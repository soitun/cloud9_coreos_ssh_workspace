FROM node:0.12.2

ENV GID=500
ENV UID=500

# Needed to run sshd and to build cloud9ide runtime
RUN \
  apt-get update && \
  apt-get install -y build-essential openssh-server && \
  mkdir -p /var/run/sshd

# Create the cloud9 user with same uid:gid as host user
RUN \
    groupadd -g $GID cloud9 && \
    useradd -g $GID -u $UID -d /home/cloud9 -m -G sudo -s /bin/bash cloud9
    

# Install etcd so that we can interact with etcd in host environment
ENV ETCD_VERSION=v2.0.13
ADD https://github.com/coreos/etcd/releases/download/${ETCD_VERSION}/etcd-${ETCD_VERSION}-linux-amd64.tar.gz /tmp/etcdctl.tar.gz
RUN \
    tar -xvzf /tmp/etcdctl.tar.gz -C /usr/local/bin --strip-components=1 etcd-${ETCD_VERSION}-linux-amd64/etcdctl && \
    rm -rf /tmp/etcdctl.tar.gz

ENV FLEET_VERSION=v0.10.2
ADD https://github.com/coreos/fleet/releases/download/${FLEET_VERSION}/fleet-${FLEET_VERSION}-linux-amd64.tar.gz /tmp/fleetctl.tar.gz
RUN \
    tar -xvzf /tmp/fleetctl.tar.gz -C /usr/local/bin --strip-components=1 fleet-${FLEET_VERSION}-linux-amd64/fleetctl && \
    rm -rf /tmp/fleetctl.tar.gz

# Create our working directory
VOLUME /home/cloud9/workspace

USER cloud9

WORKDIR /home/cloud9

# Install cloud9ide runtime
RUN \
    wget -O - https://raw.githubusercontent.com/c9/install/master/install.sh | bash

# Add in ssh keys and c9 public key
RUN mkdir -p /home/cloud9/.ssh
ADD authorized_keys /home/cloud9/.ssh/authorized_keys
ADD id_rsa* /home/cloud9/.ssh/
ADD ssh_host_* /home/cloud9/.ssh/
ADD sshd_config /home/cloud9/.ssh/sshd_config

RUN \
    chown -R cloud9:cloud9 /home/cloud9 && \
    chmod 600 ~/.ssh/id_rsa && \
    chmod 600 ~/.ssh/ssh_host_*

EXPOSE 2222

# Run the sshd server
CMD /usr/sbin/sshd -f /home/cloud9/.ssh/sshd_config -D

