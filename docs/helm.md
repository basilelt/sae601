helm repo add gitlab https://charts.gitlab.io

helm install --namespace gitlab-runner gitlab-runner -f .gitlab/values.yaml gitlab/gitlab-runner --create-namespace

helm upgrade --namespace gitlab-runner gitlab-runner -f .gitlab/values.yaml gitlab/gitlab-runner


