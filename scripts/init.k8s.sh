#!/bin/bash

ip=$1

[ -z "$ip" ] && ip=$(ip r | grep "default" | awk '{print $3}' | sort -ru | egrep '^10.|^172.|^192.' | head -1)

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

get_distribution() {
	lsb_dist=""
	if [ -r /etc/os-release ]; then
		lsb_dist="$(. /etc/os-release && echo "$ID")"
	fi
	echo "$lsb_dist"
}

debian_install(){
    apt-get update
    apt-get -y install apt-transport-https ca-certificates curl gnupg2 software-properties-common
    curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb http://mirrors.aliyun.com/docker-ce/linux/$(. /etc/os-release; echo "$ID") $(lsb_release -cs) stable"
    apt-get update && apt-get install -y docker-ce=$(apt-cache madison docker-ce | grep 18.06 | head -1 | awk '{print $3}')
    apt-get update && apt-get install -y apt-transport-https
    curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add - 
    cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF

    apt-get update
    apt-get install -y kubelet kubeadm kubectl
}

centos_install(){
    yum install -y yum-utils device-mapper-persistent-data lvm2
    yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
    yum makecache fast
    yum -y install docker-ce-$(yum list docker-ce --showduplicates | grep 18.06 | head -1 | awk '{print $2}')
    cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

    setenforce 0
    yum install -y kubelet kubeadm kubectl
}

config_docker(){
    cat > /etc/docker/daemon.json <<EOF
{
     "insecure-registries": ["hub.pt.ysicing.me"],
     "max-concurrent-downloads": 10,
     "log-level": "warn",
     "log-driver": "json-file",
     "log-opts": {
       "max-size": "20m",
       "max-file": "2"
     }
}
EOF

    systemctl enable docker
    systemctl restart docker
}

config_kubelet(){
    echo "KUBELET_EXTRA_ARGS=--fail-swap-on=false --cgroup-driver=cgroupfs --node-ip=${ip}" > /etc/default/kubelet
    systemctl daemon-reload
    systemctl restart kubelet
}

do_install(){
    lsb_dist=$( get_distribution )
	lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"
    case "$lsb_dist" in
        ubuntu|debian)
            debian_install
        ;;
        centos)
            centos_install
        ;;
        *)
			if command_exists lsb_release; then
				dist_version="$(lsb_release --release | cut -f2)"
			fi
			if [ -z "$dist_version" ] && [ -r /etc/os-release ]; then
				dist_version="$(. /etc/os-release && echo "$VERSION_ID")"
			fi
		;;
    esac
    config_docker
    config_kubelet
    kubeadm config images pull
}

kubeadm_init(){
    kubeadm init --pod-network-cidr=192.168.0.0/16  --service-cidr=10.96.0.0/12 --apiserver-advertise-address=kubeapi.pt.ysicing.me --ignore-preflight-errors=Swap | grep "discovery-token" | grep "join" > /tmp/join
    mkdir -p $HOME/.kube
    cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    chown $(id -u):$(id -g) $HOME/.kube/config
}

init_k8s(){
    #kubectl apply -f https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/rbac-kdd.yaml
    #kubectl apply -f https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml
    #kubectl taint nodes --all node-role.kubernetes.io/master-
    kubectl apply -f https://docs.projectcalico.org/v3.5/getting-started/kubernetes/installation/hosted/etcd.yaml
    kubectl apply -f https://docs.projectcalico.org/v3.5/getting-started/kubernetes/installation/hosted/calico.yaml
    kubectl apply -f https://raw.githubusercontent.com/ysicing/kube-addons/master/weavescope/scope.yaml
    kubectl apply -f https://raw.githubusercontent.com/ysicing/kube-addons/master/dashboard/kubernetes-dashboard.yaml
    kubectl apply -f https://raw.githubusercontent.com/ysicing/kube-addons/master/dashboard/admin_role.yaml
}

show(){
    echo "scope http://${1}:30110"
    echo "dash https://${1}:30111"
    token=$(kubectl -n kube-system get secret | grep admin | awk '{print "secret/"$1}' | xargs kubectl describe -n kube-system | grep token: | awk -F: '{print $2}' | xargs echo)
    echo "token: ${token}"
    echo "${token}" > /root/dash.token
}

do_install

[ -z "$2" ] && (
    kubeadm_init $ip
    init_k8s
    show $ip
)

docker run --rm -v /usr/local/bin:/sysdir spanda/pkg tar zxf /pkg.tgz -C /sysdir

