resource "helm_release" "kiali" {
  name       = "kiali-server"
  repository = "https://kiali.org/helm-charts"
  chart      = "kiali-server"
  namespace  = "istio-system"
  version    = "1.76.0"
  create_namespace = false

  values = [
    yamlencode({
      auth = {
        strategy = "anonymous"
      }

      deployment = {
        accessibleNamespaces = ["**"]
      }

      external_services = {
        istio = {
          config_namespace = "istio-system"
        }

        prometheus = {
          url = "http://kube-prom-stack-kube-prome-prometheus.monitoring.svc:9090"
        }

        # tracing = {
        #   enabled = true
        #   url     = "http://jaeger-query.istio-system.svc:16686"
        # }
      }

      rbac = {
        create = true
      }
    })
  ]
  depends_on = [
    helm_release.istio_base,
    helm_release.istiod,
    helm_release.gateway
    ]
}



# helm upgrade --install kiali-server kiali/kiali-server \
#   -n istio-system \
#   --version 1.76.0 \
#   --set auth.strategy=anonymous \
#   --set deployment.accessibleNamespaces='{**}' \
#   --set external_services.istio.config_namespace=istio-system \
#   --set external_services.prometheus.url="http://kube-prom-stack-kube-prome-prometheus.monitoring.svc:9090" \
#   # --set external_services.tracing.enabled=true \
#   # --set external_services.tracing.url="http://jaeger-query.istio-system.svc:16686" \
#   --set rbac.create=true
