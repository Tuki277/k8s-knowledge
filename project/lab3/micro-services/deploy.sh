#!/usr/bin/env bash
# Triển khai micro-services lab lên k8s (Istio thay nginx gateway)
# Dùng: REGISTRY=tuki277 ./deploy.sh [all|build|istio|apply|status|destroy]
set -euo pipefail
cd "$(dirname "$0")"

export REGISTRY="${REGISTRY:-tuki277}"   # docker hub user / registry
export TAG="${TAG:-latest}"
NS=micro-demo

build() {
  for svc in user-service visit-service frontend; do
    docker build -t "$REGISTRY/lab3-$svc:$TAG" "./$svc"
    docker push "$REGISTRY/lab3-$svc:$TAG"
  done
}

istio() {
  if ! kubectl get ns istio-system >/dev/null 2>&1; then
    istioctl install --set profile=demo -y
  fi
  kubectl -n istio-system rollout status deploy/istiod deploy/istio-ingressgateway
}

apply() {
  kubectl apply -f k8s/00-namespace.yaml
  for f in k8s/[1-6]*.yaml; do
    envsubst '${REGISTRY} ${TAG}' < "$f" | kubectl apply -f -
  done
  kubectl -n $NS rollout status deploy/postgres deploy/redis deploy/user-service deploy/visit-service deploy/frontend
}

status() {
  kubectl -n $NS get pods,svc
  kubectl -n $NS get gateway,virtualservice,peerauthentication
  echo "Ingress: $(kubectl -n istio-system get svc istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
  echo "(nếu không có LB: kubectl -n istio-system port-forward svc/istio-ingressgateway 8080:80  -> http://localhost:8080)"
}

destroy() { kubectl delete ns $NS --ignore-not-found; }

case "${1:-all}" in
  all)     build; istio; apply; status ;;
  build)   build ;;
  istio)   istio ;;
  apply)   apply ;;
  status)  status ;;
  destroy) destroy ;;
  *) echo "usage: $0 [all|build|istio|apply|status|destroy]"; exit 1 ;;
esac
