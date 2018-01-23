FROM centos:centos7
MAINTAINER Jordi Prats

ENV HOME /root
ENV GITHUB_USERNAME NTTCom-MS
ENV REPO_PATTERN eyp-
ENV PAGES_REPO git@github.com:NTTCom-MS/NTTCom-MS.github.io.git

RUN yum install epel-release -y
RUN yum install git -y
RUN yum install curl -y

RUN mkdir -p /var/eyprepos /usr/bin

COPY eypreporting.sh /usr/bin/eypreporting.sh
COPY os_metadata.py /usr/bin/os_metadata.py

VOLUME ["/var/eyprepos"]
VOLUME ["/root/.ssh"]

CMD /bin/bash /usr/bin/eypreporting.sh
