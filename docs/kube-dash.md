kubectl apply -f k8s/dashboard/dashboard-ingress.yaml


kubectl create serviceaccount dashboard-admin -n kube-system

kubectl create clusterrolebinding dashboard-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=kube-system:dashboard-admin

kubectl create token dashboard-admin -n kube-system

