resource "kubernetes_manifest" "kyverno_namespace_label" {
  manifest = {
    apiVersion = "kyverno.io/v1"
    kind       = "ClusterPolicy"
    metadata = {
      name = "add-istio-monitor-label"
    }
    spec = {
      rules = [
        {
          name = "add-istio-monitor"
          match = {
            resources = {
              kinds = ["Pod"]
            }
          }
          mutate = {
            patchStrategicMerge = {
              metadata = {
                labels = {
                  "istio" = "monitor"
                }
              }
            }
          }
        }
      ]
    }
  }
}

