# Deploying Monitoring Stack on Kubespray Cluster

This guide explains how to deploy a monitoring stack with Prometheus and Grafana on your Kubespray-managed Kubernetes cluster using Helm.

## Prerequisites

- A running Kubernetes cluster set up with Kubespray
- Helm installed on your machine
- kubectl configured to communicate with your cluster
- NGINX Ingress Controller installed on your cluster

## Installation Steps

### 1. Create a Monitoring Namespace

First, create a namespace for monitoring components:

```bash
kubectl create namespace monitoring
```

### 2. Create a PersistentVolume and PersistentVolumeClaim

```bash
kubectl apply -f k8s/grafana/grafana-pv.yaml
kubectl apply -f k8s/prometheus/prometheus-pv.yaml
kubectl apply -f k8s/grafana/grafana-pvc.yaml
```

### 3. Install Prometheus Using Helm

Prometheus will collect metrics from your Kubernetes cluster, including the metrics-server data.

#### Add the Prometheus Helm Repository

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

#### Install Prometheus

```bash
helm install prometheus prometheus-community/prometheus \
  --namespace monitoring \
  --values k8s/prometheus/values.yaml
```

### 4. Install Grafana using Helm

#### Add the Grafana Helm Repository

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

#### Install Grafana Using Helm

Use the configuration from the values.yaml file:

```bash
helm install grafana grafana/grafana \
  --namespace monitoring \
  --values k8s/grafana/values.yaml
```

### 5. Verify the Deployment

Check that Grafana pods are running:

```bash
kubectl get pods -n monitoring
kubectl get svc -n monitoring
```

### 6. Access Grafana

#### Using NGINX Ingress (for external access)

Apply the NGINX Ingress configuration:

```bash
kubectl apply -f k8s/grafana/ingress.yaml
```

Important: Make sure to:
1. Update `grafana.kube.basile.uha.fr` in the ingress.yaml file to your actual domain name
2. Configure your DNS to point to your Ingress Controller's external IP or load balancer
3. If you require TLS/SSL, uncomment and configure the TLS section

After applying the Ingress configuration, you should be able to access Grafana at `http://grafana.kube.basile.uha.fr` (or `https://` if TLS is configured).

### 7. Login Credentials

The default login credentials are configured in values.yaml:
- Username: admin
- Password: admin

## Configuring Data Sources

Grafana is pre-configured with Prometheus as a data source at `http://prometheus-server.monitoring.svc.cluster.local`. This will automatically collect metrics from:

- Kubernetes API server
- Kubernetes Nodes
- Kubernetes Pods with prometheus annotations
- Kubernetes Services with prometheus annotations
- Metrics-server data (via Kubernetes API and cAdvisor)

## Adding Dashboards

While some default dashboards are configured in values.yaml, here are some useful dashboards for Kubernetes monitoring:

1. Log in to Grafana
2. Go to "+" > Import
3. Enter these Grafana.com dashboard IDs:
   - 315: Kubernetes Cluster Monitoring
   - 7249: Kubernetes Cluster (Prometheus)
   - 8588: Kubernetes Deployment Statefulset Daemonset metrics
   - 11454: Kubernetes Node Exporter Full


## Uninstalling Your Monitoring Stack

To remove Grafana, Prometheus and their Ingresses from your cluster:

```bash
kubectl delete namespace monitoring
```

## Troubleshooting

- **Pod not starting**: Check events with `kubectl describe pod -n monitoring <pod-name>`
- **Cannot access dashboards**: Verify the services are running with `kubectl get svc -n monitoring`
- **Missing metrics**: Check if Prometheus targets are being scraped: Access Prometheus UI and go to Status > Targets
- **Ingress not working**: Check if the Ingress resources are properly configured with `kubectl describe ingress -n monitoring`

### PersistentVolume Issues

If you see an error like `pod has unbound immediate PersistentVolumeClaims`, your pod is unable to start because the required storage cannot be provisioned. This is a common issue with both Grafana and Prometheus pods.

1. **Check available StorageClasses**:
   ```bash
   kubectl get storageclass
   ```

2. **Verify PVC status**:
   ```bash
   kubectl get pvc -n monitoring
   ```
