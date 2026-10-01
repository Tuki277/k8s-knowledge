kubectl apply -f ns.yaml 

kubectl apply -f pod.yaml 

kubectl get pod -n car-serv

kubectl exec -it car-serv -n car-serv -- /bin/bash 

kubectl delete -f pod.yaml