# Deploying Grafana on Kubespray Cluster

This guide explains how to deploy Grafana on your Kubespray-managed Kubernetes cluster using Helm to visualize metrics.

## Prerequisites

- A running Kubernetes cluster set up with Kubespray
- Helm installed on your machine
- kubectl configured to communicate with your cluster
- NGINX Ingress Controller installed on your cluster
- Metrics source (like Prometheus) already running in the cluster (optional)

## Installation Steps

### 1. Create a Namespace

First, create a namespace for Grafana:

```bash
kubectl create namespace monitoring
```

### 2. Add the Grafana Helm Repository

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

### 3. Install Grafana Using Helm

Use the configuration from the values.yaml file:

```bash
helm install grafana grafana/grafana \
  --namespace monitoring \
  --values k8s/grafana/values.yaml
```

### 4. Verify the Deployment

Check that Grafana pods are running:

```bash
kubectl get pods -n monitoring
kubectl get svc -n monitoring
```

### 5. Access Grafana

#### Using Port-Forward (for local access)

```bash
kubectl port-forward -n monitoring svc/grafana 3000:80
```

Then access Grafana at http://localhost:3000

#### Using NGINX Ingress (for external access)

Apply the NGINX Ingress configuration:

```bash
kubectl apply -f k8s/grafana/ingress.yaml
```

Important: Make sure to:
1. Update `grafana.example.com` in the ingress.yaml file to your actual domain name
2. Configure your DNS to point to your Ingress Controller's external IP or load balancer
3. If you require TLS/SSL, uncomment and configure the TLS section

After applying the Ingress configuration, you should be able to access Grafana at `http://grafana.example.com` (or `https://` if TLS is configured).

### 6. Login Credentials

The default login credentials are configured in values.yaml:
- Username: admin
- Password: admin

## Configuring Data Sources

Grafana is pre-configured with Prometheus as a data source if it's available at `http://prometheus-server.monitoring.svc.cluster.local`. If your Prometheus setup differs, you'll need to modify the data source configuration.

You can add or modify data sources through the Grafana UI:

1. Log in to Grafana
2. Go to Configuration > Data Sources
3. Add or edit data sources as needed

## Adding Dashboards

While some default dashboards are configured in values.yaml, you can import additional dashboards:

1. Log in to Grafana
2. Click on "+" > Import
3. Enter a Grafana.com dashboard ID or upload a dashboard JSON file
4. Select your data source and import

## Upgrading Grafana

To upgrade your Grafana installation:

```bash
helm repo update
helm upgrade grafana grafana/grafana \
  --namespace monitoring \
  --values k8s/grafana/values.yaml
```

## Uninstalling Grafana

To remove Grafana and its Ingress from your cluster:

```bash
kubectl delete -f k8s/grafana/ingress.yaml
helm uninstall grafana -n monitoring
```

## Troubleshooting

- **Pod not starting**: Check events with `kubectl describe pod -n monitoring <pod-name>`
- **Cannot access Grafana**: Verify the service is running with `kubectl get svc -n monitoring grafana`
- **Data source not working**: Check connectivity between Grafana and your metrics source
- **Ingress not working**: Check if the Ingress resource is properly configured with `kubectl describe ingress -n monitoring grafana` and ensure your NGINX Ingress Controller is running
