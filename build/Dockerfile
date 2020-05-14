FROM quay.io/operator-framework/ansible-operator:v0.17.0

COPY requirements.yml ${HOME}/requirements.yml
COPY image_resources/centos8-appstream.repo /etc/yum.repos.d/centos8-appstream.repo
RUN ansible-galaxy collection install -r ${HOME}/requirements.yml \
 && chmod -R ug+rwx ${HOME}/.ansible

USER root
RUN dnf install -y --nodocs redis --enablerepo=centos8-appstream && dnf clean all

# Temporally workaround to fix https://github.com/operator-framework/operator-sdk/issues/2648
RUN ln -s ${HOME}/.ansible /.ansible

COPY group_vars/ ${HOME}/group_vars/
COPY roles/ ${HOME}/roles/
COPY watches.yaml ${HOME}/watches.yaml
COPY playbook.yml ${HOME}/playbook.yml
USER 1001
