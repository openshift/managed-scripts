# Pre-install packages
FROM quay.io/centos/centos:8
# update all packages
RUN yum -y upgrade
# Install packages
RUN yum update -y \
    yum upgrade -y \
    yum install tar wget -y \

# Replace version with a version number to pin a specific version (eg: "4.7.8")
ARG OC_VERSION="stable"
ENV OC_URL="https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/${OC_VERSION}"

# Directory for the extracted binaries, etc
RUN mkdir -p /out

# Install the latest OC Binary from the mirror
RUN mkdir /oc
WORKDIR /oc

# Download the checksum
RUN curl -sSLf ${OC_URL}/sha256sum.txt -o sha256sum.txt

# Download the binary tarball
RUN /bin/bash -c "curl -sSLf -O ${OC_URL}/$(awk -v asset="openshift-client-linux" '$0~asset {print $2}' sha256sum.txt)"

# Check the tarball and checksum match
RUN sha256sum --check --ignore-missing sha256sum.txt
RUN tar --extract --gunzip --no-same-owner --directory /out oc --file *.tar.gz

# Make binaries executable
RUN chmod -R +x /out

# Copy previously acquired binaries into the $PATH
ENV BIN_DIR="/usr/local/bin"
COPY --from=builder /out/oc ${BIN_DIR}

# Validate
RUN oc completion bash > /etc/bash_completion.d/oc

# Cleanup Home Dir
RUN rm /root/anaconda* /root/original-ks.cfg

WORKDIR /root
ENTRYPOINT ["/bin/bash"]
