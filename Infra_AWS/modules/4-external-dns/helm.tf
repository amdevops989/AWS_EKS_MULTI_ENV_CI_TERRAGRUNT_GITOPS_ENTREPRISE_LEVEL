resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  namespace  = var.k8s_namespace
  version    = var.helm_chart_version

  values = [
    yamlencode({
      provider       = "aws"
      aws            = { region = var.region }
      serviceAccount = {
        create = false
        name   = kubernetes_service_account.external_dns.metadata[0].name
      }
      timeout       = 300
      domainFilters = var.domain_filters
      txtOwnerId    = var.cluster_name
      policy        = "upsert-only"
      zoneType      = var.zone_type
      extraArgs     = ["--zone-id-filter=${var.hosted_zone_id}"]

      # -----------------------
      # Force to main node group
      # -----------------------
      nodeSelector = {
        role = "main"   # <- matches your MNG label
      }

      # No tolerations needed since MNG has no taints
    })
  ]

  depends_on = [
    kubernetes_service_account.external_dns,
    aws_iam_role_policy_attachment.external_dns_attach
  ]
}
