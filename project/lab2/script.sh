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

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace

kubectl get pods -n argocd -w

kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
echo

kubectl port-forward svc/argocd-server -n argocd 8080:443

helm repo add signoz https://charts.signoz.io
helm repo update

kubectl get storageclass

helm install signoz signoz/signoz \
  --namespace signoz \
  --create-namespace \
  --wait \
  --timeout 1h \
  -f signoz-values.yaml

kubectl port-forward -n signoz svc/signoz 8080:8080

kubectl apply -f tunnel.yaml

# update để có thể route domain bằng cloudflare tunnel

helm upgrade jenkins jenkins/jenkins -n jenkins --set controller.jenkinsUriPrefix="/jenkins" --reuse-values

export KUBE_EDITOR="nano"

helm upgrade argocd argo/argo-cd -n argocd \
  --set server.insecure=true \
  --reuse-values

kubectl patch configmap argocd-cmd-params-cm -n argocd \
  --type merge \
  -p '{"data":{"server.insecure":"true"}}'

kubectl get pods -n argocd -w

kubectl exec -it -n postgresql postgresql-0 -- bash

PGPASSWORD=<pg-password> psql -U postgres -c "CREATE DATABASE lab2;"

PGPASSWORD=<pg-password> psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE lab2 TO postgres;"

kubectl logs jenkins-0 -n jenkins -c init

helm repo add signoz https://charts.signoz.io
helm repo update

helm install k8s-infra signoz/k8s-infra \
  --namespace signoz \
  -f k8s-infra-values.yaml

kubectl get pods -n signoz -l app.kubernetes.io/name=k8s-infra
kubectl logs -n signoz -l app.kubernetes.io/component=otel-agent --tail=50

kubectl patch daemonset k8s-infra-otel-agent -n signoz --type='json' -p='[
  {"op": "remove", "path": "/spec/template/spec/containers/0/volumeMounts/3/mountPropagation"}
]'

helm upgrade k8s-infra signoz/k8s-infra -n signoz -f k8s-infra-values.yaml --reuse-values

# Vào pod backend
kubectl exec -it -n lab2 deployment/backend-deployment -- sh

# Test DNS resolution
nslookup signoz-otel-collector.signoz.svc.cluster.local

# Test kết nối TCP đến port 4318
nc -zv signoz-otel-collector.signoz.svc.cluster.local 4318

# 1. Xem log crash
kubectl logs -n lab2 -l app=backend --previous --tail=100

# 2. Kiểm tra biến môi trường đã inject đúng chưa
kubectl exec -it -n lab2 deployment/backend-deployment -- env | sort

# 3. Test kết nối DB từ pod backend (nếu pod còn sống đủ lâu)
kubectl exec -it -n lab2 deployment/backend-deployment -- sh -c "nc -zv postgresql.postgresql.svc.cluster.local 5432"

# 4. Test kết nối Redis
kubectl exec -it -n lab2 deployment/backend-deployment -- sh -c "nc -zv redis-master.redis.svc.cluster.local 6379"

# chỉ giữ lại 3 deployment
kubectl patch deployment backend-deployment -n lab2 -p '{"spec":{"revisionHistoryLimit":3}}'

# jenkins add node
# Xóa file cũ
rm -f agent.jar

# Tải lại file mới (thêm -L để theo dõi chuyển hướng)
curl -L -u admin:admin123 -o agent.jar https://k8s-on-prem.squad-xteam.com/jenkins/jnlpJars/agent.jar

# Kiểm tra lại kích thước và loại file
ls -lh agent.jar
file agent.jar

kubectl get pvc -n postgresql

kubectl exec -it postgresql-0 -n postgresql -- df -h /bitnami/postgresql

kubectl get storageclass

kubectl get storageclass <tên-storage-class-của-bạn> -o jsonpath='{.allowVolumeExpansion}'

# docker desktop
kubectl patch storageclass hostpath -p '{"allowVolumeExpansion": true}'

kubectl get storageclass hostpath -o jsonpath='{.allowVolumeExpansion}'

kubectl patch pvc data-postgresql-0 -n postgresql -p '{"spec":{"resources":{"requests":{"storage":"10Gi"}}}}'

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# cho docker desktop
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

kubectl apply -f hpa.yaml

helm repo add chaos-mesh https://charts.chaos-mesh.org
helm repo update

helm install chaos-mesh chaos-mesh/chaos-mesh \
  --namespace chaos-mesh \
  --create-namespace \
  --set chaosDaemon.runtime=containerd \
  --set chaosDaemon.socketPath=/run/containerd/containerd.sock

# cho docker desktop
helm install chaos-mesh chaos-mesh/chaos-mesh \
  --namespace chaos-mesh \
  --create-namespace \
  --set chaosDaemon.runtime=docker \
  --set chaosDaemon.socketPath=/var/run/docker.sock

# vault
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update