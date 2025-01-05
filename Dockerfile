FROM quay.io/operator-framework/ansible-operator:v1.32.0
USER root

COPY requirements.yml ${HOME}/requirements.yml
RUN python3 -m pip install --no-cache-dir jmespath
RUN ansible-galaxy collection install community.general
RUN ansible-galaxy collection list
RUN ansible-galaxy collection install -r ${HOME}/requirements.yml \
 && chmod -R ug+rwx ${HOME}/.ansible

COPY image_resources/centos9-appstream.repo /etc/yum.repos.d/centos9-appstream.repo
RUN dnf install -y --nodocs redis openssl --enablerepo=centos9-appstream-* && dnf clean all

COPY resources/kernel-cache-drop-daemonset.yaml /opt/kernel_cache_dropper/
COPY watches.yaml ${HOME}/watches.yaml
COPY roles/ ${HOME}/roles/
COPY playbooks/ ${HOME}/playbooks/
USER 1001
