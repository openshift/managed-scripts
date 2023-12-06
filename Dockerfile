FROM registry.access.redhat.com/ubi8/ubi:latest AS build-stage0
ARG OC_VERSION="stable"
ENV OC_URL="https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/${OC_VERSION}"

# AWS cli args and env variables
# Replace AWS client zipfile with specific file to pin to a specific version
# (eg: "awscli-exe-linux-x86_64-2.0.30.zip")
ARG AWSCLI_VERSION="awscli-exe-linux-x86_64.zip"
ENV AWSCLI_URL="https://awscli.amazonaws.com/${AWSCLI_VERSION}"

# install tools needed for installation
RUN yum install -y unzip git make go

# Directory for the extracted binary
RUN mkdir -p /out

# Install the latest OC Binary from the mirror and scripts
RUN mkdir /oc
WORKDIR /oc

# Download the checksum
RUN curl -sSLf ${OC_URL}/sha256sum.txt -o sha256sum.txt

# Download the binary x86 tarball
RUN export OC_LINUX_X86_CLIENT=$(cat sha256sum.txt | grep openshift-client-linux | grep -v arm64 | awk '{print $2; exit}') && \
    curl -sSLf -O ${OC_URL}/${OC_LINUX_X86_CLIENT}

# Check the tarball and checksum match
RUN sha256sum --check --ignore-missing sha256sum.txt
RUN tar --extract --gunzip --no-same-owner --directory /out oc --file *.tar.gz

### Temporary solution to integrate the oc-hc
ENV OC_HC_TAR_URL="https://github.com/givaldolins/openshift-cluster-health-check/releases/download/v0.1.3/oc-hc-v0.1.3-linux-amd64.tar.gz"
ENV OC_HC_MD5="e75e9a9801601e53d7ad555b498e7c08"
RUN mkdir -p /oc-hc
WORKDIR /oc-hc

# Download the binary and md5
RUN curl -sSLf -O $OC_HC_TAR_URL

# Check md5sum for the downloaded tar
RUN md5sum -b oc-hc-v0.1.3-linux-amd64.tar.gz | grep $OC_HC_MD5

# Extract the binary
RUN tar xzf oc-hc-v0.1.3-linux-amd64.tar.gz --directory /out


### Attach yq binary into the image
ENV YQ_URL="https://github.com/mikefarah/yq/releases/download/v4.35.1/yq_linux_amd64.tar.gz"
ENV YQ_MD5="be32a02446da244ebe5b94c3834b2c97"
RUN mkdir -p /yq
WORKDIR /yq

# Download the yq release
RUN curl -sSLf -O $YQ_URL

# Check md5sum for the downloaded tar
RUN md5sum yq_linux_amd64.tar.gz | grep $YQ_MD5

# Extract the yq binary
RUN tar xzf yq_linux_amd64.tar.gz --directory /out

# Install aws-cli
RUN mkdir -p /aws/bin
WORKDIR /aws
# Download the awscli zip file
RUN curl -sSLf $AWSCLI_URL -o awscliv2.zip
# Extract the awscli zip
RUN unzip awscliv2.zip
# Install the libs to the usual location, so the symlinks will be right
# The final image build will copy them later
# Install the bins to the /aws/bin dir so the final image build copy is easier
RUN ./aws/install -b /aws/bin

## Attach ocm binary into the image
# Setting ENV variables
ENV OCM_URL="https://github.com/openshift-online/ocm-cli/releases/download/v0.1.67/ocm-linux-amd64"
ENV OCM_SHA256_CHECKSUM="2ac055237f0ca9b6e5ef7a03666c670bbbb778e9e6d96a41bf8f0968b1618265  ocm-linux-amd64"

# Creating a working directory
RUN mkdir -p /ocm-cli
WORKDIR /ocm-cli

# Downloading the ocm binary
RUN curl -sSLf -O $OCM_URL

# Checking the SHA-256 hash
RUN echo $OCM_SHA256_CHECKSUM | sha256sum -c -

# Moving the validated ocm binary to /out and make it executable
RUN mv ocm-linux-amd64 /out/ocm
RUN chmod +x /out/ocm

# Attach hypershift binary into the image
# TODO: Currently there is no pre-build hypershift bin yet, once
# it is ready we need to update this to fetch the released bin directly
# Fetch the source code
RUN mkdir -p /hypershift
WORKDIR /hypershift
RUN git clone https://github.com/openshift/hypershift.git /hypershift
# Build binary
RUN OUT_DIR=/out make hypershift

# Make binaries executable
RUN chmod -R +x /out

FROM registry.access.redhat.com/ubi8/ubi:latest
RUN  yum -y install --disableplugin=subscription-manager \
     python3.11 python3.11-pip jq openssh-clients sshpass \
     && yum --disableplugin=subscription-manager clean all
COPY --from=build-stage0 /out/oc  /usr/local/bin
COPY --from=build-stage0 /out/oc-hc  /usr/local/bin
COPY --from=build-stage0 /out/yq_linux_amd64  /usr/local/bin/yq
COPY --from=build-stage0 /aws/bin/  /usr/local/bin
COPY --from=build-stage0 /usr/local/aws-cli /usr/local/aws-cli
COPY --from=build-stage0 /out/hypershift /usr/local/bin
COPY --from=build-stage0 /out/ocm /usr/local/bin
COPY scripts /managed-scripts

# Install python packages
RUN python3 -m pip install --upgrade pip
RUN python3 -m pip install tabulate openshift-client check-jsonschema --user

# Validate
RUN oc completion bash > /etc/bash_completion.d/oc
RUN aws --version

# Cleanup Home Dir
RUN rm /root/anaconda* /root/original-ks.cfg

USER 1001
WORKDIR /managed-scripts
