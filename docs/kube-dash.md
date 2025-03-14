# Kubernetes Dashboard Setup Guide

This guide will help you deploy and configure the Kubernetes Dashboard, a web-based UI for managing your Kubernetes cluster.

## Installation

### 1. Configure Ingress Access

```bash
# Apply the custom ingress configuration for the dashboard
kubectl apply -f k8s/dashboard/dashboard-ingress.yaml
```

## Authentication Setup

### 1. Create Service Account for Dashboard Admin

```bash
kubectl create serviceaccount dashboard-admin -n kube-system
```

### 2. Create ClusterRoleBinding

```bash
kubectl create clusterrolebinding dashboard-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=kube-system:dashboard-admin
```

### 3. Create Token for Authentication

```bash
# Create a secret for a long-lived token
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: dashboard-admin-token
  namespace: kube-system
  annotations:
    kubernetes.io/service-account.name: dashboard-admin
type: kubernetes.io/service-account-token
EOF
```

### 4. Retrieve the Authentication Token

```bash
kubectl get secret dashboard-admin-token -n kube-system -o jsonpath="{.data.token}" | base64 --decode
```

## Accessing the Dashboard

1. Navigate to the URL specified in your ingress configuration

2. Use the token generated in the previous step to log in

## Troubleshooting

If you encounter issues:

```bash
# Check if dashboard pods are running
kubectl get pods -n kubernetes-dashboard

# Check ingress configuration
kubectl get ingress -n kubernetes-dashboard

# View pod logs
kubectl logs -n kubernetes-dashboard -l k8s-app=kubernetes-dashboard
```
