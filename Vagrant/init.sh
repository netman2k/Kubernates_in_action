#!/bin/bash
echo -e "\nDisabling SELinux..."
setenforce 0
sed -i 's/^\(SELinux=\)Enforcing/\1disabled/' /etc/selinux/config

echo -e "\nDisabling swap..."
swapoff -a

echo -e "\nDisabling FirewallD..."
systemctl disable firewalld && systemctl stop $_

echo -e "\nAdding the Kubernates repository..."
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://yum.kubernetes.io/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

echo -e "\nInstalling some packages..."
yum install -y docker kubelet kubeadm kubectl kubernates-cni

echo -e "\nEnabling services..."
systemctl enable docker && systemctl start $_
systemctl enable kubelet && systemctl start $_

echo -e "\nEnabling NET.BRIDGE.BRIDGE-NF-CALL-IPTABLES Kernel Option..."
sysctl -w net.bridge.bridge-nf-call-iptables=1
echo "net.bridge.bridge-nf-call-iptables=1" > /etc/sysctl.d/k8s.conf

