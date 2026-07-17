resource "helm_release" "sealed_secrets" {
  name       = "sealed-secrets"
  namespace  = "kube-system"
  repository = "https://bitnami-labs.github.io/sealed-secrets"
  chart      = "sealed-secrets"
  version    = "2.18.0"  # use latest stable
  create_namespace = true
  values = [
    yamlencode({
      # optional customization
      fullnameOverride = "sealed-secrets"
    })
  ]
}
