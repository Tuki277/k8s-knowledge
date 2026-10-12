sudo swapoff -a
sudo systemctl restart containerd
sudo systemctl restart kubelet
sleep 30
sudo crictl ps | grep apiserver
kubectl get nodes