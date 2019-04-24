FROM quay.io/operator-framework/ansible-operator:v0.7.0

COPY group_vars/ ${HOME}/group_vars/
COPY roles/ ${HOME}/roles/
COPY watches.yaml ${HOME}/watches.yaml
COPY playbook.yml ${HOME}/playbook.yml

USER root
RUN yum install redis -y
#RUN git clone http://github.com/antirez/redis.git
#RUN cd redis && git checkout 4.0 && make redis-cli
#RUN ln -s "$PWD/src/redis-cli" /usr/bin/redis-cli
USER 1001

