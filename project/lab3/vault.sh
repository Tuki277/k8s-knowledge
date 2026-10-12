helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

helm install vault hashicorp/vault \
  --namespace vault \
  --create-namespace \
  -f vault-values.yaml \
    --set agent.nodeSelector."role"=worker