helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.type=LoadBalancer \
  --set controller.ingressClassResource.default=true

helm repo add jetstack https://charts.jetstack.io

helm repo update

helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --set crds.enabled=true

kubectl -n cert-manager rollout status deploy/cert-manager-webhook

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

helm repo add jenkins https://charts.jenkins.io
helm repo update

kubectl create namespace jenkins

helm install jenkins jenkins/jenkins \
  --namespace jenkins \
  --create-namespace \
  --set controller.adminPassword='admin123' \
  --set controller.serviceType=ClusterIP

kubectl get secret --namespace jenkins jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode; echo

kubectl --namespace jenkins port-forward svc/jenkins 8080:8080

helm repo add bitnami https://charts.bitnami.com/bitnami

helm repo update

helm install postgresql bitnami/postgresql \
  --namespace postgresql \
  --create-namespace \
  --set auth.postgresPassword='matkhau123' \
  --set auth.database='mydb' \
  --set primary.persistence.size=8Gi

# ket noi ben trong cluster
kubectl run postgresql-client --rm --tty -i --restart='Never' \
  --namespace postgresql \
  --image docker.io/bitnami/postgresql:16 \
  --env="PGPASSWORD=$POSTGRES_PASSWORD" \
  --command -- psql --host postgresql -U postgres -d postgres -p 5432

kubectl port-forward --namespace postgresql svc/postgresql 5432:5432

helm install redis bitnami/redis \
  --namespace redis \
  --create-namespace \
  --set architecture=standalone \
  --set auth.password='matkhau123' \
  --set master.persistence.size=2Gi

# ket noi local
kubectl run redis-client --rm --tty -i --restart='Never' \
  --namespace redis \
  --image docker.io/bitnami/redis:7.2 \
  --env REDIS_PASSWORD=$REDIS_PASSWORD \
  --command -- redis-cli -h redis-master -a $REDIS_PASSWORD

kubectl port-forward --namespace redis svc/redis-master 6379:6379