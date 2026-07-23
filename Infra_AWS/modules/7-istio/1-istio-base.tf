# helm repo add istio https://istio-release.storage.googleapis.com/charts
# helm repo update
# helm install my-istio-base-release -n istio-system --create-namespace istio/base --set global.istioNamespace=istio-system
resource "helm_release" "istio_base" {
  name             = "my-istio-base-release"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "base"
  namespace        = "istio-system"
  create_namespace = true
  version          = "1.17.1"

  set {
    name  = "global.istioNamespace"
    value = "istio-system"
  }
  
  depends_on = [
    aws_security_group_rule.istio_pilot,
    aws_security_group_rule.istio_sidecar,
    aws_security_group_rule.istio_envoy_admin,
    aws_security_group_rule.istio_metrics
  ]
}
