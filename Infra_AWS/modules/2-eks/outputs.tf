###############################################################################
# EKS Outputs – for addons (cert-manager, external-dns, ALB, Karpenter, etc.)
###############################################################################

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_ca_certificate" {
  description = "Base64 encoded CA certificate"
  value       = module.eks.cluster_certificate_authority_data
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA"
  value       = module.eks.oidc_provider_arn
}

output "oidc_provider_url" {
  description = "OIDC provider URL (without https://)"
  value       = module.eks.oidc_provider
}

output "cluster_security_group_id" {
  description = "Cluster security group ID"
  value       = module.eks.cluster_security_group_id
}

output "node_security_group_id" {
  description = "Node shared security group ID"
  value       = module.eks.node_security_group_id
}

output "region" {
  description = "AWS region"
  value       = data.aws_region.current.name
}

output "mng_nodegroup_name" {
  description = "The name of the managed node group (MNG) for critical addons like metrics-server"
  value       = keys(module.eks.eks_managed_node_groups)[0]  # or ["karpenter"] if fixed
}

