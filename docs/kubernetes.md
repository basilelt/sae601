# Kubernetes Cluster Setup and Management
## Prerequisites
### Python Environment Setup
```bash
# Install Python 3.12
cd kubespray
pyenv install 3.12
pyenv local 3.12

# Create and activate a virtual environment
python -m venv .venv
source .venv/bin/activate
```

### Required Python Packages
```bash
# Upgrade pip
pip install --upgrade pip

# Install required packages
pip install -r requirements.txt
```

## Kubernetes Cluster Setup
### Deploy Kubernetes Cluster
```bash
ansible-playbook cluster.yml -b -v
```

## Cluster Management
### Reset Kubernetes Cluster
If you need to reset your Kubernetes cluster and start fresh:
```bash
# Reset the entire cluster
ansible-playbook reset.yml -b -v

# Reset only specific nodes (using limit)
ansible-playbook reset.yml -b -v --limit node1,node2
```

### Access Cluster

```bash
# Configure kubectl to use the cluster
mkdir -p ~/.kube
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

# Verify cluster status
kubectl get nodes
kubectl get pods --all-namespaces
```

## Troubleshooting

### Check Node Status
```bash
kubectl get nodes
kubectl describe node <node-name>
```

### Check Pod Status
```bash
kubectl get pods --all-namespaces
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
```
