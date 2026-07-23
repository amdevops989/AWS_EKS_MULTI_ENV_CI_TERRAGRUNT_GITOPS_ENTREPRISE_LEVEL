resource "helm_release" "gateway" {
  name = "gateway"

  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "gateway"
  namespace        = "istio-ingress"
  create_namespace = true
  version          = "1.17.1"

  # Force Gateway pods onto the main MNG node group
  set {
    name  = "nodeSelector.role"
    value = "main"
  }

  # 1. ExternalDNS Annotation for Route 53 A-record
  set {
    name  = "service.annotations.external-dns\\.alpha\\.kubernetes\\.io/hostname"
    value = var.domain_filters
  }

  # 2. Force AWS Network Load Balancer (NLB) via AWS Load Balancer Controller
  set {
    name  = "service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "external" # Uses AWS LB Controller instead of in-tree controller
  }

  set {
    name  = "service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-nlb-target-type"
    value = "instance" # or "ip" if using VPC CNI directly
  }

  set {
    name  = "service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
    value = "internet-facing"
  }

  set {
    name  = "service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-attributes"
    value = "load_balancing.cross_zone.enabled=true"
  }

  depends_on = [
    helm_release.istio_base,
    helm_release.istiod
  ]
}