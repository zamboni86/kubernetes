sudo su

# installing kubeadm
yum update -y

# disable SELinux.
echo 'disabling SELinux...'
setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux

# enable the br_netfilter module for cluster communication.
echo 'enable br_netfilter...'
modprobe br_netfilter
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables

# install docker prerequisites
yum install -y yum-utils device-mapper-persistent-data lvm2

# install docker
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce

# configure the docker Cgroup driver to systemd, enable and start docker
sed -i '/^ExecStart/ s/$/ --exec-opt native.cgroupdriver=systemd/' /usr/lib/systemd/system/docker.service 
systemctl daemon-reload
systemctl enable docker --now
systemctl status docker
docker info | grep -i cgroup

# add the Kubernetes repo.
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
      https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

# install kubernetes
yum install -y kubelet kubeadm kubectl

systemctl enable kubelet

# initialize the cluster using the IP range for Flannel.
kubeadm init --pod-network-cidr=10.244.0.0/16

#exit sudo
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# deploy flannel
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# check cluster status
kubectl get pods --all-namespaces
