FROM quay.io/operator-framework/ansible-operator:v1.9.0
USER root

COPY requirements.yml ${HOME}/requirements.yml
RUN ansible-galaxy collection install -r ${HOME}/requirements.yml \
 && chmod -R ug+rwx ${HOME}/.ansible

COPY image_resources/centos8-appstream.repo /etc/yum.repos.d/centos8-appstream.repo
RUN dnf install -y --nodocs redis openssl --enablerepo=centos8-appstream-*
RUN dnf clean all

COPY resources/kernel-cache-drop-daemonset.yaml /opt/kernel_cache_dropper/
COPY watches.yaml ${HOME}/watches.yaml
COPY roles/ ${HOME}/roles/
COPY playbooks/ ${HOME}/playbooks/
USER 1001
