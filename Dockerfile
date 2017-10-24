#
# Base image
FROM centos:7

#
# Install latest updates
RUN yum install -y && \
    yum clean all

#
# Install baseline tools
RUN yum install -y git && \
    yum install -y wget && \
    yum install -y openssh-server && \
    yum install -y java-1.8.0-openjdk && \
    yum install -y sudo

#
# generate ssh host keys for SSHD
RUN /usr/bin/ssh-keygen -A

#
# set Jenkins environment variables
ENV JENKINS_HOME /var/jenkins_home
ENV JENKINS_SLAVE_AGENT_PORT 50000
ENV JENKINS_VERSION 2.73.2

#
# create Jenkins user
RUN useradd -d "$JENKINS_HOME" -u 1000 -m -s /bin/bash jenkins

#
# setup volume for home directory for data persistence
VOLUME /var/jenkins_home

#
# download jenkins
# moving war file to a separate location as I do not want it to persist when upgrading.
RUN curl -fL http://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-war/${JENKINS_VERSION}/jenkins-war-${JENKINS_VERSION}.war -o /usr/share/jenkins/jenkins.war
