#!/bin/bash

[ -f "/vagrant/install.sh" ] && (
    /vagrant/prepare.sh
)
echo $1 $2

curl -sSL https://repo.spanda.io/kun/kunsh/raw/branch/master/install/k8s/init.sh | bash -s install --ip $2
if [ "$1" != 1 ];then
    kubeadm reset
fi