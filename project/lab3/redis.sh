helm repo add bitnami https://charts.bitnami.com/bitnami

helm repo update

helm install redis bitnami/redis \
  --namespace redis \
  --create-namespace \
  --set architecture=standalone \
  --set auth.password='Tuki277' \
  --set master.persistence.size=4Gi \
  --set agent.nodeSelector."role"=worker