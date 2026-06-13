resource "kubernetes_namespace" "external_dns" {
  metadata {
    name = var.k8s_namespace
  }
}

resource "kubernetes_service_account" "external_dns" {
  metadata {
    name      = var.service_account_name
    namespace = kubernetes_namespace.external_dns.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.external_dns.arn
    }
  }
}
