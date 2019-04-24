FROM quay.io/operator-framework/ansible-operator:v0.6.0

COPY group_vars/ ${HOME}/group_vars/
COPY roles/ ${HOME}/roles/
COPY watches.yaml ${HOME}/watches.yaml
COPY playbook.yml ${HOME}/playbook.yml

USER root
RUN yum install -y redis
USER 1001
