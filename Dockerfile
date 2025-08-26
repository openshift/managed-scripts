FROM registry.access.redhat.com/ubi8/ubi:8.9 AS build-stage0

ARG OC_VERSION="stable-4.15"
ENV OC_URL="https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/${OC_VERSION}"

# AWS cli args and env variables
# Replace AWS client zipfile with specific file to pin to a specific version
# (eg: "awscli-exe-linux-x86_64-2.0.30.zip")
ARG AWSCLI_VERSION="awscli-exe-linux-x86_64.zip"
ENV AWSCLI_URL="https://awscli.amazonaws.com/${AWSCLI_VERSION}"

# install tools needed for installation
RUN yum install -y unzip git make gcc

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
ENV YQ_URL="https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64.tar.gz"
ENV YQ_CHECKSUMS="https://github.com/mikefarah/yq/releases/latest/download/checksums"
ENV YQ_CHECKSUM_TOOL="https://github.com/mikefarah/yq/releases/latest/download/extract-checksum.sh"
ENV YQ_CHECKSUMS_HASHES_ORDER="https://github.com/mikefarah/yq/releases/latest/download/checksums_hashes_order"
# ENV YQ_MD5="7e8bff5d0342f0090e866825cc75d2fc"
RUN mkdir -p /yq
WORKDIR /yq

# Download the yq release
RUN curl -sSLf -O $YQ_URL

# Extract the md5sum for the release
RUN curl -sSLf -O $YQ_CHECKSUM_TOOL
RUN curl -sSLf -O $YQ_CHECKSUMS
RUN curl -sSLf -O $YQ_CHECKSUMS_HASHES_ORDER

# Check md5sum for the downloaded tar
RUN sh extract-checksum.sh MD5 yq_linux_amd64.tar.gz | awk '{ print $2 " " $1}' | md5sum -c -

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
ENV OCM_URL="https://github.com/openshift-online/ocm-cli/releases/latest/download/ocm-linux-amd64"
ENV OCM_SHA256_CHECKSUM_URL="https://github.com/openshift-online/ocm-cli/releases/latest/download/ocm-linux-amd64.sha256"

# Creating a working directory
RUN mkdir -p /ocm-cli
WORKDIR /ocm-cli

# Downloading the ocm binary
RUN curl -sSLf -O $OCM_URL

# Checking the SHA-256 hash
RUN curl -sSLf $OCM_SHA256_CHECKSUM_URL | sha256sum -c -

# Moving the validated ocm binary to /out and make it executable
RUN mv ocm-linux-amd64 /out/ocm
RUN chmod +x /out/ocm

# Install golang with specific version
# The go is used to build the hypershift binary, so make it match with the one in hypershift repo
ENV HYPERSHIFT_GO_MOD="https://raw.githubusercontent.com/openshift/hypershift/main/go.mod"
RUN echo "export GO_VERSION=$(curl -sSLf $HYPERSHIFT_GO_MOD | grep -E "go\s+[0-9]+\.[0-9]+\.[0-9]+" | awk -F ' ' '{print $2}')" > /out/envfile
RUN . /out/envfile ; curl -sSLf https://go.dev/dl/go$GO_VERSION.linux-amd64.tar.gz -o go$GO_VERSION.linux-amd64.tar.gz
RUN . /out/envfile ; rm -rf /usr/local/go && tar -C /usr/local -xzf go$GO_VERSION.linux-amd64.tar.gz
ENV PATH=$PATH:/usr/local/go/bin
RUN go version

# Attach hypershift binary into the image
# TODO: Currently there is no pre-build hypershift bin yet, once
# it is ready we need to update this to fetch the released bin directly
# Fetch the source code
RUN mkdir -p /hypershift
WORKDIR /hypershift
RUN git clone https://github.com/openshift/hypershift.git /hypershift
# Build binary
RUN OUT_DIR=/out make hypershift

# Attach osdctl binary into the image
# Fetch the source code
RUN mkdir -p /osdctl
WORKDIR /osdctl
RUN git clone https://github.com/openshift/osdctl.git /osdctl
# Build binary
RUN make build
RUN cp osdctl /out/osdctl

# Make binaries executable
RUN chmod -R +x /out

FROM registry.access.redhat.com/ubi8/ubi:8.9
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
COPY --from=build-stage0 /out/osdctl /usr/local/bin
COPY scripts /managed-scripts

# Install python packages
RUN python3 -m pip install --upgrade pip
RUN python3 -m pip install tabulate openshift-client check-jsonschema --user

# Validate
RUN oc completion bash > /etc/bash_completion.d/oc
RUN aws --version

# Cleanup Home Dir
RUN rm -f /root/anaconda* /root/original-ks.cfg
WORKDIR /root
