output "iam_role_arn" {
  description = "ARN of the generated IRSA role"
  value       = aws_iam_role.eso.arn
}

output "helm_release_status" {
  description = "Status of the Helm release"
  value       = helm_release.external_secrets.status
}