# helm repo add istio https://istio-release.storage.googleapis.com/charts
# helm repo update
# helm install gateway -n istio-ingress --create-namespace istio/gateway
resource "helm_release" "gateway" {
  name = "gateway"

  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "gateway"
  namespace        = "istio-ingress"
  create_namespace = true
  version          = "1.17.1"

  set {
    name  = "service.annotations.external-dns\\.alpha\\.kubernetes\\.io/hostname"
    value = var.domain_filters   # wildcard using variable
  }
  # 🔥 ADD THIS
  set {
    name  = "nodeSelector.role"
    value = "main"
  }


  depends_on = [
    helm_release.istio_base,
    helm_release.istiod
  ]
}