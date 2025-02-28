output "gitlab_ip" {
  description = "The IP address of the GitLab container"
  value       = var.ip_address
}

output "gitlab_url_http" {
  description = "The HTTP URL to access GitLab"
  value       = "http://gitlab.basile.local"
}

output "gitlab_url_https" {
  description = "The HTTPS URL to access GitLab"
  value       = "https://gitlab.basile.local"
}

output "gitlab_registry_url" {
  description = "The registry URL"
  value       = "gitlab.basile.local:5050"
}
