resource "helm_release" "istio_base" {
  name = "my-istio-base-release"

  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "base"
  namespace        = "istio-system"
  create_namespace = true
  version          = "1.17.1"

  # Added equals sign here
  set = [
    {
      name  = "global.istioNamespace"
      value = "istio-system"
    }
  ]
}

resource "helm_release" "istiod" {
  name = "my-istiod-release"

  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "istiod"
  namespace        = "istio-system"
  create_namespace = true
  version          = "1.17.1"

  # Combined into a single set assignment array
  set = [
    {
      name  = "telemetry.enabled"
      value = "true"
    },
    {
      name  = "global.istioNamespace"
      value = "istio-system"
    },
    {
      name  = "meshConfig.ingressService"
      value = "istio-gateway"
    },
    {
      name  = "meshConfig.ingressSelector"
      value = "gateway"
    }
  ]

  depends_on = [helm_release.istio_base]
}

resource "helm_release" "gateway" {
  name = "gateway"

  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "gateway"
  namespace        = "istio-ingress"
  create_namespace = true
  version          = "1.17.1"

  depends_on = [
    helm_release.istio_base,
    helm_release.istiod
  ]
}