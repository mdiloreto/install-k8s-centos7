# 1. Disable Swap (required for Kubernetes)
sudo swapoff -a

# 1.b Configure Hostnames: <<<< Review hostnames and modify as needed >>>>

sudo hostnamectl set-hostname master-node
sudo hostnamectl set-hostname worker-node1


# 2. Set SELinux in permissive mode (disables enforcement but logs potential denials)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

#3. Install docker/containerd

sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine

sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

sudo yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin  

sudo systemctl start docker
sudo systemctl enable docker

# 4. Add de kubernetes Repo <<Take into account the url for the k8s distro/version>>

cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
EOF

# 5. Install kubelet, kubeadm, and kubectl
sudo yum install -y kubelet kubeadm kubectl
sudo systemctl enable kubelet
sudo systemctl start kubelet


# 6. Configure the sysctl settings for Kubernetes networking
echo '1' | sudo tee /proc/sys/net/bridge/bridge-nf-call-iptables
echo '1' | sudo tee /proc/sys/net/ipv4/ip_forward
sudo modprobe br_netfilter

# 7. Modify Hosts file

sudo vi /etc/hosts

x.x.x.x  master-node
x.x.x.x  worker-node1

#8. Firewall rules for the Master-Node

# Start and enable firewalld
sudo systemctl start firewalld
sudo systemctl enable firewalld

# Allow traffic for the Kubernetes API Server
sudo firewall-cmd --permanent --add-port=6443/tcp

# Allow traffic for etcd server client API
sudo firewall-cmd --permanent --add-port=2379-2380/tcp

# Allow traffic for Kubelet API
sudo firewall-cmd --permanent --add-port=10250/tcp

# Allow traffic for Kube-scheduler
sudo firewall-cmd --permanent --add-port=10251/tcp

# Allow traffic for Kube-controller-manager
sudo firewall-cmd --permanent --add-port=10252/tcp

# If using NodePort services, allow the default range (you can adjust this range based on your configuration)
sudo firewall-cmd --permanent --add-port=30000-32767/tcp

# Allow traffic for Flannel (if using Flannel as the network plugin)
sudo firewall-cmd --permanent --add-port=8472/udp  # For VXLAN
sudo firewall-cmd --permanent --add-port=8285/udp  # For backend UDP traffic

# Reload firewalld to apply the changes
sudo firewall-cmd --reload

# Check the list of added rules
sudo firewall-cmd --list-all

# 8.b Firewall rules for the Worker-Nodes

# Start and enable firewalld
sudo systemctl start firewalld
sudo systemctl enable firewalld

# Allow traffic for Kubelet API
sudo firewall-cmd --permanent --add-port=10250/tcp

# Allow traffic for Kube-proxy and NodePort services to ensure external connectivity to services
sudo firewall-cmd --permanent --add-port=30000-32767/tcp

# If using Flannel as the network plugin, open the VXLAN port
sudo firewall-cmd --permanent --add-port=8472/udp  # For VXLAN
sudo firewall-cmd --permanent --add-port=8285/udp  # For backend UDP traffic (if used)

# Allow traffic for Calico, if using Calico as the network plugin
# sudo firewall-cmd --permanent --add-port=4789/udp # VXLAN
# sudo firewall-cmd --permanent --add-port=179/tcp  # BGP (only if using BGP mode)

# Reload firewalld to apply the changes
sudo firewall-cmd --reload

# Check the list of added rules
sudo firewall-cmd --list-all
