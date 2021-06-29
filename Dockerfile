FROM quay.io/operator-framework/ansible-operator:v1.7.2
USER root

COPY requirements.yml ${HOME}/requirements.yml
RUN ansible-galaxy collection install -r ${HOME}/requirements.yml \
 && chmod -R ug+rwx ${HOME}/.ansible

COPY image_resources/centos8-appstream.repo /etc/yum.repos.d/centos8-appstream.repo
RUN dnf install -y --nodocs redis openssl --enablerepo=centos8-appstream && dnf clean all

COPY group_vars/ ${HOME}/group_vars/
COPY templates/ ${HOME}/templates/
COPY watches.yaml ${HOME}/watches.yaml
COPY roles/ ${HOME}/roles/
COPY playbooks/ ${HOME}/playbooks/
USER 1001