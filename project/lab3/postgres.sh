helm repo add bitnami https://charts.bitnami.com/bitnami

helm repo update

helm install postgresql bitnami/postgresql \
  --namespace postgresql \
  --create-namespace \
  --set auth.postgresPassword='U2sUQ06H2zS09vZ8' \
  --set auth.database='mydb' \
  --set primary.persistence.size=10Gi \
    --set agent.nodeSelector."role"=worker