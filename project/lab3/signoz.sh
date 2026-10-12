helm repo add signoz https://charts.signoz.io
helm repo update

kubectl get storageclass

helm install signoz signoz/signoz \
  --namespace signoz \
  --create-namespace \
  --wait \
  --timeout 1h \
  --set agent.nodeSelector."role"=worker \
  -f signoz-values.yaml \
    --set agent.nodeSelector."role"=worker

helm install k8s-infra signoz/k8s-infra \
  --namespace signoz \
  -f k8s-infra-values.yaml

kubectl get pods -n signoz -l app.kubernetes.io/name=k8s-infra
kubectl logs -n signoz -l app.kubernetes.io/component=otel-agent --tail=50

kubectl patch daemonset k8s-infra-otel-agent -n signoz --type='json' -p='[
  {"op": "remove", "path": "/spec/template/spec/containers/0/volumeMounts/3/mountPropagation"}
]'

helm upgrade k8s-infra signoz/k8s-infra -n signoz -f k8s-infra-values.yaml --reuse-values