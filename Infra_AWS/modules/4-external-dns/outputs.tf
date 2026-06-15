output "service_account_name" {
  value = kubernetes_service_account.external_dns.metadata[0].name
}

output "iam_role_arn" {
  value = aws_iam_role.external_dns.arn
}
