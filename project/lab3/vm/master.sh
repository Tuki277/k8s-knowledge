export KUBE_EDITOR="nano"

sudo apt install -y conntrack

sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=<VM_IP>

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubeadm join 10.10.1.90:6443 --token 58pz8s.yiafbxpxqgrdut3o \
        --discovery-token-ca-cert-hash sha256:da1e3bc8d1920c48d4f76fb9ccbc7e5d57a46b968f17a27795f1012adeaacf81

kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.31.3/manifests/operator-crds.yaml

kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.31.3/manifests/tigera-operator.yaml

kubectl apply -f calico-installation.yaml

kubectl label node worker-1 worker-2 worker-3 role=worker

kubectl get nodes --show-labels | grep worker