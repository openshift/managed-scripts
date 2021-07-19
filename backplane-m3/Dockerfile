FROM centos:8
LABEL maintainer="revyas@redhat.com"
RUN yum update -y
RUN yum upgrade -y
RUN yum install tar wget -y
RUN cd /opt
RUN wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz
RUN tar -xvf openshift-client-linux.tar.gz
RUN mv oc kubectl /usr/local/bin
CMD ["/bin/bash"]
