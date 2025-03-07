# GitLab Runner Installation with CoreDNS Configuration

## Setup Kubeconfig
```bash
export KUBECONFIG=kubespray/inventory/mycluster/artifacts/admin.conf
```

# Create namespace first
```bash
kubectl create namespace gitlab-runner
```

# Install helm repo
```bash
helm repo add gitlab https://charts.gitlab.io
```

# For initial installation
```bash
cat k8s/runner/gitlab.basile.local.crt | base64 -w 0  # Copy the output in k8s/runner/cert-config.yml
kubectl apply -f k8s/runner/cert-secret.yml
helm install --namespace gitlab-runner gitlab-runner -f k8s/runner/values.yaml gitlab/gitlab-runner
```

# If runner is already installed, upgrade it with the new configuration
```bash
helm upgrade --namespace gitlab-runner gitlab-runner -f k8s/runner/runner/values.yaml gitlab/gitlab-runner
```

# To check the status of your runner pods
```bash
kubectl get pods -n gitlab-runner
```

# To view logs from the runner pod
```bash
kubectl logs -n gitlab-runner -l app=gitlab-runner -f
```

# To delete if needed
```bash
helm uninstall gitlab-runner -n gitlab-runner
kubectl delete configmap <my-config> -n gitlab-runner
```
