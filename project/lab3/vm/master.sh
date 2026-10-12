export KUBE_EDITOR="nano"

sudo apt install -y conntrack

sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=<VM_IP>

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubeadm join 10.10.11.29:6443 --token wrfl3c.m6dkiwa1gdfjndah \
        --discovery-token-ca-cert-hash sha256:b2c34b23b1158106e73187bbc9851194472215c214e844a54f5c30c4ce1c5e3d

kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.31.3/manifests/operator-crds.yaml

kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.31.3/manifests/tigera-operator.yaml

kubectl apply -f calico-installation.yaml

kubectl label node worker-1 worker-2 worker-3 role=worker

kubectl get nodes --show-labels | grep worker