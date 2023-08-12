#!/bin/sh

docker network create footloose-cluster

# make sure we have an up-to-date image for the footloose nodes
docker pull korvus/debian10:0.6.3

footloose create

# Copy the trust bundle, if exists, and configure docker for Docker/k3s to work behind a proxy
if [[ -f tls-ca-bundle.pem ]]
  docker cp tls-ca-bundle.pem footloose-k8s-node0:/etc/ssl/certs/
  docker cp tls-ca-bundle.pem footloose-k8s-node1:/etc/ssl/certs/
  docker cp tls-ca-bundle.pem footloose-k8s-node2:/etc/ssl/certs/
fi
  
# set up k3s on node0 as the master
footloose ssh root@node0 -- "env INSTALL_K3S_SKIP_DOWNLOAD=true env INSTALL_K3S_SELINUX_WARN=true /root/install-k3s.sh"

# get the token from node0
export k3stoken=$(footloose ssh root@node0 -- cat /var/lib/rancher/k3s/server/node-token)

# set up k3s on node1 and node2 with the token from node0
footloose ssh root@node1 -- "env INSTALL_K3S_SKIP_DOWNLOAD=true env K3S_URL=https://node0:6443 env K3S_TOKEN=$k3stoken env INSTALL_K3S_SELINUX_WARN=true /root/install-k3s.sh"
footloose ssh root@node2 -- "env INSTALL_K3S_SKIP_DOWNLOAD=true env K3S_URL=https://node0:6443 env K3S_TOKEN=$k3stoken env INSTALL_K3S_SELINUX_WARN=true /root/install-k3s.sh"

