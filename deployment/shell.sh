kubectl apply -f deployment.yaml 

kubectl delete -f deployment.yaml

# get replica set
kubectl get rs

# các lệnh deployment thường dùng

# Cập nhật trực tiếp số lượng replicas
kubectl scale deployment <ten-deployment> --replicas=<so-replicas>

# Xem chi tiết cụ thể về một Deployment
kubectl describe deployment -n <namespace>

# Xem cấu hình YAML của một Deployment
kubectl get deployment <ten-deployment> -o yaml

# Cập nhật Deployment bằng cách thay đổi hình ảnh container
kubectl set image deployment/<ten-deployment> <ten-container>=<ten-image>:<tag-moi>

# Rollback Deployment về phiên bản trước
kubectl rollout undo deployment <ten-deployment>

# Kiểm tra lịch sử các phiên bản của Deployment
kubectl rollout history deployment <ten-deployment>

# Liệt kê các Pod được tạo bởi một Deployment cụ thể
kubectl get pods -l app=<ten-deployment> -n <namespace>

# Cập nhật biến môi trường cho các container trong Deployment
kubectl set env deployment/<ten-deployment> <key>=<value>