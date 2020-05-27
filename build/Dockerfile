FROM quay.io/operator-framework/ansible-operator:v0.17.1
USER root

COPY requirements.yml ${HOME}/requirements.yml
RUN ansible-galaxy collection install -r ${HOME}/requirements.yml \
 && chmod -R ug+rwx ${HOME}/.ansible

RUN rpm --nodeps -i http://mirror.centos.org/centos/8-stream/BaseOS/x86_64/os/Packages/centos-repos-8.1-1.1911.0.9.el8.x86_64.rpm http://mirror.centos.org/centos/8-stream/BaseOS/x86_64/os/Packages/centos-gpg-keys-8.1-1.1911.0.7.el8.noarch.rpm
RUN dnf install -y --nodocs redis && dnf clean all

COPY group_vars/ ${HOME}/group_vars/
COPY roles/ ${HOME}/roles/
COPY meta/ ${HOME}/meta/
COPY watches.yaml ${HOME}/watches.yaml
COPY playbook.yml ${HOME}/playbook.yml
USER 1001
