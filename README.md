## Overview

1) Setup master all the way
2) Setup minions then

```
CLUSTER_NAME=test

SERVICE_IP_RANGE=10.0.0.0/16
CLUSTER_POD_IP_RANGE=10.10.0.0/16
POD_IP_RANGES=10.10.x.0/24
```

### Provision

provision master and 2 minions as Ubuntu 15.04

set hostnames, private ip setup, /etc/hosts (https://www.linode.com/docs/networking/linux-static-ip-configuration)

```
apt-get update
apt-get upgrade -y
```

### get binaries and files

```
mkdir -p /tmp/kube-build && cd /tmp/kube-build
wget https://github.com/kubernetes/kubernetes/releases/download/v1.0.3/kubernetes.tar.gz
tar xzvf kubernetes.tar.gz
tar xzvf kubernetes/server/kubernetes-server-linux-amd64.tar.gz
kubernetes/cluster/ubuntu/build.sh
cp binaries/kubectl binaries/minion/* /usr/bin
# MASTER ONLY: cp binaries/master/* /usr/bin
cd -
```

```
git clone https://github.com/yanatan16/kubernetes-linode-setup
```

### Certs

On the master:

```
bin/make-ca-cert.sh <PUBLIC_IP> IP:10.0.0.1,DNS:kubernetes,DNS:kubernetes.default,DNS:kubernetes.default.svc,DNS:kubernetes.default.svc.cluster.local,DNS:kube-master-01
ls /srv/kubernetes
```

### Docker

First configure the bridge: `kubelet --configure-cbr0=true --pod-cidr=10.10.x.0/24` and ctrl+c to kill kubelet after it logs `Starting kubelet main sync loop.`

```
apt-get install -y docker.io

mkdir -p /etc/sysconfig
cp sysconfig/docker /etc/sysconfig

systemctl enable docker.service
systemctl start docker.service
```

## kubelet and kube-proxy

All servers:


```
mkdir -p /etc/sysconfig
mkdir -p /etc/kubernetes/manifests

cp systemd/kubelet.service systemd/kube-proxy.service /etc/systemd/system
cp sysconfig/kubelet sysconfig/kube-proxy /etc/sysconfig

systemctl enable /etc/systemd/system/kubelet.service
systemctl start kubelet.service

systemctl enable /etc/systemd/system/kube-proxy.service
systemctl start kube-proxy.service
```

## etcd and kubernetes on master

```
cp manifests/*.manifest /etc/kubernetes/manifests
```

should take 30 seconds or so to start all those services up.

### Flannel

```
cat flannel_config.json | etcdctl set /coreos.com/network/config

cp sysconfig/flanneld /etc/sysconfig
cp systemd/flanneld.service /etc/systemd/system

systemctl enable /etc/systemd/system/flanneld.service
systemctl start flanneld.service
```

### Reconfigure docker

We have to reconfigure docker once flannel is running to get routing correct. This is a bit chicken and the egg, but it should work.

```
systemctl stop docker kubelet
cp systemd/docker.service /lib/systemd/system/docker.service
systemctl daemon-reload
systemctl start docker kubelet
```

### Test

Setup kubectl

```
mkdir ~/.kube
cp kubeconfig ~/.kube/config
```

```
$ kubectl get nodes
NAME             LABELS                                  STATUS
kube-master-01   kubernetes.io/hostname=kube-master-01   Ready
kube-pool-01     kubernetes.io/hostname=kube-pool-01     Ready
kube-pool-02     kubernetes.io/hostname=kube-pool-02     Ready
```

### Test

See https://github.com/kubernetes/kubernetes/blob/v1.0.5/examples/simple-nginx.md

and hopefully you can ping the apiserver service:

```
curl https://10.0.0.1:443
```