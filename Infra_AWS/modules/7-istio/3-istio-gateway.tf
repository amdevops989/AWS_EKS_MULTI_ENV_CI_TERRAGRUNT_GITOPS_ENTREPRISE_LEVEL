resource "helm_release" "gateway" {
  name = "gateway"

  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "gateway"
  namespace        = "istio-ingress"
  create_namespace = true
  version          = "1.17.1"

  # Increase timeout to give AWS enough time to provision the NLB
  timeout = 900
  wait    = true

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

  # 2. Native EKS In-Tree Network Load Balancer (NLB) Configuration
  set {
    name  = "service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "nlb" # Replaced "external" to let the built-in K8s service-controller provision the NLB directly
  }

  set {
    name  = "service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
    value = "internet-facing"
  }

  set {
    name  = "service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-backend-protocol"
    value = "tcp"
  }

# 🌟 CRITICAL FOR SERVICEMONITOR: Expose Envoy metrics port on the Gateway K8s Service
  set {
    name  = "service.extraPorts[0].name"
    value = "http-envoy-prom"
  }
  set {
    name  = "service.extraPorts[0].port"
    value = 15090
  }
  set {
    name  = "service.extraPorts[0].targetPort"
    value = 15090
  }

  depends_on = [
    helm_release.istio_base,
    helm_release.istiod
  ]
}