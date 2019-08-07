FROM quay.io/operator-framework/ansible-operator:v0.6.0

COPY group_vars/ ${HOME}/group_vars/
COPY roles/ ${HOME}/roles/
COPY watches.yaml ${HOME}/watches.yaml
COPY playbook.yml ${HOME}/playbook.yml
USER root
RUN yum install -y redis python-redis git numpy
RUN git clone https://github.com/parallel-fs-utils/fs-drift
RUN chown -R 1001:1001 fs-drift
USER 1001
