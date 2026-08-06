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
      
      # 🌟 Enable Istio Gateway / VirtualService monitoring
      sources       = var.sources

      # 🌟 Dynamic per-environment ownership with fallback
      txtOwnerId    = var.txt_owner_id != "" ? var.txt_owner_id : "external-dns-${var.env}"
      txtPrefix     = var.txt_prefix
      
      policy        = "upsert-only"
      zoneType      = var.zone_type
      extraArgs     = ["--zone-id-filter=${var.hosted_zone_id}"]

      # -----------------------
      # Force to main node group
      # -----------------------
      nodeSelector = {
        role = "main" # <- matches your MNG label
      }
    })
  ]

  depends_on = [
    kubernetes_service_account.external_dns,
    aws_iam_role_policy_attachment.external_dns_attach
  ]
}