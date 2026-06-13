output "cert_manager_service_account" {
  value       = kubernetes_service_account.cert_manager_sa.metadata[0].name
  description = "Cert-Manager service account name"
}

output "cert_manager_release_name" {
  value       = helm_release.cert_manager.name
  description = "Helm release name for Cert-Manager"
}

output "cert_manager_namespace" {
  value       = kubernetes_namespace.cert_manager.metadata[0].name
  description = "Namespace where cert-manager is deployed"
}
