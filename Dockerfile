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
ENV JENKINS_OPTS="--logfile=/var/log/jenkins/jenkins.log  --webroot=/var/cache/jenkins/war"

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

#
# setup jenkins directories

RUN mkdir -p /usr/share/jenkins/ref/init.groovy.d
RUN mkdir /var/log/jenkins
RUN mkdir /var/cache/jenkins

RUN chown -R jenkins "$JENKINS_HOME" /usr/share/jenkins/ref/init.groovy.d
RUN chown -R jenkins:jenkins /var/log/jenkins
RUN chown -R jenkins:jenkins /var/cache/jenkins


#
# ### NOTES ###
# taken from official jenkins docker github repo: https://github.com/jenkinsci/docker

#
# upload local configs
COPY init.groovy /usr/share/jenkins/ref/init.groovy.d/tcp-slave-agent-port.groovy
COPY jenkins.sh /usr/local/bin/jenkins.sh
COPY plugins.sh /usr/local/bin/plugins.sh
RUN chmod +x /usr/local/bin/plugins.sh
RUN chmod +x /usr/local/bin/jenkins.sh

#
# install plugins
COPY plugins.txt /tmp/plugins.txt
RUN /usr/local/bin/plugins.sh /tmp/plugins.txt

#
# be user jenkins when running container
USER jenkins

#
# Expose Ports for web and slave agents
EXPOSE 8080
EXPOSE 50000

#
# ### NOTES ###
# taken from official jenkins docker github repo: https://github.com/jenkinsci/docker

#
# tini environment variables
ENV TINI_VERSION 0.9.0
ENV TINI_SHA fa23d1e20732501c3bb8eeeca423c89ac80ed452

#
# Use tini as subreaper in Docker container to adopt zombie processes
RUN curl -fsSL https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-static -o /bin/tini && chmod +x /bin/tini \
  && echo "$TINI_SHA  /bin/tini" | sha1sum -c -

ENTRYPOINT ["/bin/tini", "--", "/usr/local/bin/jenkins.sh"]
