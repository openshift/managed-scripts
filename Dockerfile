FROM registry.access.redhat.com/ubi8/ubi:latest AS build-stage0
ARG OC_VERSION="stable"
ENV OC_URL="https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/${OC_VERSION}"

# AWS cli args and env variables
# Replace AWS client zipfile with specific file to pin to a specific version
# (eg: "awscli-exe-linux-x86_64-2.0.30.zip")
ARG AWSCLI_VERSION="awscli-exe-linux-x86_64.zip"
ENV AWSCLI_URL="https://awscli.amazonaws.com/${AWSCLI_VERSION}"
ENV AWSSIG_URL="https://awscli.amazonaws.com/${AWSCLI_VERSION}.sig"

# install tools needed for installation
RUN yum install -y unzip

# Directory for the extracted binary
RUN mkdir -p /out

# Install the latest OC Binary from the mirror and scripts
RUN mkdir /oc
WORKDIR /oc

# Download the checksum
RUN curl -sSLf ${OC_URL}/sha256sum.txt -o sha256sum.txt

# Download the binary tarball
RUN /bin/bash -c "curl -sSLf -O ${OC_URL}/$(awk -v asset="openshift-client-linux" '$0~asset {print $2}' sha256sum.txt)"

# Check the tarball and checksum match
RUN sha256sum --check --ignore-missing sha256sum.txt
RUN tar --extract --gunzip --no-same-owner --directory /out oc --file *.tar.gz

# Install aws-cli
RUN mkdir -p /aws/bin
WORKDIR /aws
# Download the awscli zip file
RUN curl -sSLf $AWSCLI_URL -o awscliv2.zip
# Extract the awscli zip
RUN unzip awscliv2.zip
# Install the libs to the usual location, so the simlinks will be right
# The final image build will copy them later
# Install the bins to the /aws/bin dir so the final image build copy is easier
RUN ./aws/install -b /out

# Make binaries executable
RUN chmod -R +x /out

FROM registry.access.redhat.com/ubi8/ubi:latest
RUN  yum -y install --disableplugin=subscription-manager \
     python3  \
     && yum --disableplugin=subscription-manager clean all
COPY --from=build-stage0 /out/oc  /usr/local/bin
COPY --from=build-stage0 /out/aws  /usr/local/bin
COPY scripts /managed-scripts

# Validate
RUN oc completion bash > /etc/bash_completion.d/oc

# Cleanup Home Dir
RUN rm /root/anaconda* /root/original-ks.cfg
WORKDIR /root
