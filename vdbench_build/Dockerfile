FROM centos:7

USER root
RUN yum update -y \
    && yum install -y https://centos7.iuscommunity.org/ius-release.rpm \
    && yum install -y java screen which \
    && yum install -y python36u python36u-libs python36u-devel python36u-pip \
    && yum clean all

RUN pip3 install --upgrade pip
RUN pip3 install --user XlsxWriter

RUN  mkdir /opt/vdbench  /mnt/pvc
COPY vdbench50407 /opt/vdbench

WORKDIR /opt/vdbench
CMD ["/bin/bash"]
