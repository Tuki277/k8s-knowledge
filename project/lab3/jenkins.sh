helm repo add jenkins https://charts.jenkins.io

helm repo update

kubectl create namespace jenkins

helm install jenkins jenkins/jenkins \
  --namespace jenkins \
  --create-namespace \
  --set controller.admin.password='HoangHuy@01' \
  --set controller.serviceType=ClusterIP \
  --set controller.nodeSelector."role"=worker \
  --set agent.nodeSelector."role"=worker

kubectl get secret --namespace jenkins jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode; echo

kubectl logs jenkins-0 -n jenkins -c init