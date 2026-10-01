helm repo add rancher-stable https://releases.rancher.com/server-charts/stable

helm repo update

kubectl create namespace cattle-system

helm upgrade --install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --set hostname=rancher.127.0.0.1.sslip.io \
  --set replicas=1 \
  --set bootstrapPassword=admin123456 \
  --set ingress.ingressClassName=nginx \
  --set ingress.tls.source=rancher

kubectl -n cattle-system rollout status deploy/rancher
