FROM centos:7

USER root
RUN yum install -y java
RUN curl -O --location https://github.com/brianfrankcooper/YCSB/releases/download/0.15.0/ycsb-0.15.0.tar.gz
RUN mkdir ycsb
RUN tar xzf ycsb-0.15.0.tar.gz -C ycsb --strip-components 1
#RUN tar xfvz ycsb-0.15.0.tar.gz
#RUN mv ycsb-0.15.0 ycsb
