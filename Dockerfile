#
# Base image
FROM centos:7

#
# Install latest updates
RUN yum install -y && \
    yum clean all
