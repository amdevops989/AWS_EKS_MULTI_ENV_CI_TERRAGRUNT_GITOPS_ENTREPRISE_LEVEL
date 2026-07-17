# helm install kyverno kyverno/kyverno \
#   -n kyverno \
#   --create-namespace \
#   --set enableWebhook=true

resource "helm_release" "kyverno" {
  name       = "kyverno"
  namespace  = "kyverno"
  repository = "https://kyverno.github.io/kyverno/"
  chart      = "kyverno"
  version    = "3.6.2"

  create_namespace = true

  values = [
    yamlencode({
      admissionController = {
        replicas = 2 # ✅ HA for EKS
      }

      backgroundController = {
        replicas = 1
      }

      cleanupController = {
        replicas = 1
      }

      reportsController = {
        replicas = 1
      }

      features = {
        policyExceptions = true
      }

      config = {
        webhooks = {
          failurePolicy = "Fail"
        }
      }

      podSecurityStandard = {
        enabled = false # ❗ PSA handled by K8s itself
      }
    })
  ]
}

