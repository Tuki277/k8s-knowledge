kubectl apply -f pv.yaml -n monitoring

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

helm repo update

helm upgrade --install prometheus prometheus-community/kube-prometheus-stack 
  --namespace monitoring 
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.accessModes[0]=ReadWriteOnce 
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=10Gi 
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName=nfs-storage
  --set prometheus-node-exporter.hostRootFsMount.enabled=true
  --set prometheus-node-exporter.hostRootFsMount.mountPropagation=None

# <tên ingress>.192.168.0.104.nip.io request host ở local 

kubectl apply -f storageclass.yaml

kubectl rollout restart deploy/prometheus-kube-prometheus-operator -n monitoring

helm upgrade prometheus prometheus-community/kube-prometheus-stack -n monitoring -f values.yaml