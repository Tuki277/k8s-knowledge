helm repo add jetstack https://charts.jetstack.io

helm repo update

helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --set crds.enabled=true \
  --set nodeSelector."role"=worker

kubectl -n cert-manager rollout status deploy/cert-manager-webhook --timeout=180s

kubectl get pods -n cert-manager
kubectl get crds | grep cert-manager

helm repo add rancher-stable https://releases.rancher.com/server-charts/stable

helm repo update

kubectl create namespace cattle-system

helm install rancher rancher-stable/rancher \
  --namespace cattle-system --create-namespace \
  --set hostname=rancher.squad-xteam.com \
  --set replicas=1 \
  --set ingress.tls.source=rancher \
  --set ingress.ingressClassName=nginx \
  --set global.cattle.psp.enabled=false \
  --set nodeSelector."role"=worker

kubectl patch ingress rancher -n cattle-system --type=merge -p '
{
  "metadata": {
    "annotations": {
      "nginx.ingress.kubernetes.io/ssl-redirect": "false"
    }
  }
}'

helm upgrade rancher rancher-stable/rancher \
  --namespace cattle-system \
  --set hostname=rancher.squad-xteam.com \
  --set replicas=1 \
  --set tls=external \
  --set ingress.ingressClassName=nginx \
  --set global.cattle.psp.enabled=false \
  --set nodeSelector."role"=worker

kubectl patch ingress rancher -n cattle-system --type=merge -p '
{
  "metadata": {
    "annotations": {
      "nginx.ingress.kubernetes.io/use-forwarded-headers": "true"
    }
  }
}'