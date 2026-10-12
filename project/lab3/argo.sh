helm repo add argo https://argoproj.github.io/argo-helm

helm repo update

helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --set nodeSelector."role"=worker \
  --set server.insecure=true

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

kubectl patch configmap argocd-cmd-params-cm -n argocd --type=merge -p '{"data":{"server.insecure":"true"}}'kubectl rollout restart deployment argocd-server -n argocd