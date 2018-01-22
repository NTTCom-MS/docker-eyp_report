FROM centos:centos7
MAINTAINER Jordi Prats

ENV HOME /root
ENV GITHUB_USERNAME NTTCom-MS
ENV REPO_PATTERN eyp-

RUN yum install epel-release -y
RUN yum install git -y
RUN yum install curl -y

RUN mkdir -p /var/eyprepos /usr/bin

COPY eypreporting.sh /usr/bin/eypreporting.sh

VOLUME ["/var/eyprepos"]
VOLUME ["/root/.ssh"]

CMD /bin/bash /usr/bin/eypreporting.sh
