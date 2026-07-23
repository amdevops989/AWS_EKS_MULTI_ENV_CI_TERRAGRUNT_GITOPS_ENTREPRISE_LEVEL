resource "kubernetes_namespace" "kyverno" {
  metadata {
    name = var.kyverno_namespace
  }
}

resource "kubernetes_service_account" "kyverno_sa" {
  metadata {
    name      = "kyverno-sa"
    namespace = kubernetes_namespace.kyverno.metadata[0].name
  }
}
resource "helm_release" "kyverno" {
  name       = "kyverno"
  chart      = "kyverno"
  repository = "https://kyverno.github.io/kyverno/"
  namespace  = kubernetes_namespace.kyverno.metadata[0].name
  version    = var.kyverno_chart_version

  create_namespace = false

  values = [
    yamlencode({
      serviceAccount = {
        create = false
        name   = kubernetes_service_account.kyverno_sa.metadata[0].name
      }

      installCRDs = true

      # Core controllers
      admissionController  = { replicas = 1 }
      backgroundController = { replicas = 1 }
      cleanupController    = { replicas = 1 }
      reportsController    = { replicas = 1 }  # Must be >= 1

      # Features: disable heavy reporting to save resources
      features = {
        policyExceptions = { enabled = true }
        reporting        = { enabled = false }
        admissionReports = { enabled = false }
        aggregateReports = { enabled = false }
        policyReports    = { enabled = false }
        validatingAdmissionPolicyReports = { enabled = false }
        mutatingAdmissionPolicyReports   = { enabled = false }
        backgroundScan   = { enabled = true }
        configMapCaching = { enabled = true }
        deferredLoading  = { enabled = true }
        globalContext    = { enabled = true }
        logging          = { enabled = true }
        omitEvents       = { enabled = true }
        registryClient   = { enabled = true }
        tuf              = { enabled = true }
      }

      config = {
        webhooks = { failurePolicy = "Fail" }
      }

      podSecurityStandard = { enabled = false }

      # -----------------------
      # Force pods to main node group
      # -----------------------
      nodeSelector = {
        role = "main"   # matches your main node group label
      }

      # Optional: keep for consistency
      # tolerations = [
      #   { key = "CriticalAddonsOnly", operator = "Exists" }
      # ]

      priorityClassName = "system-cluster-critical"
    })
  ]

  depends_on = [
    kubernetes_namespace.kyverno,
    kubernetes_service_account.kyverno_sa
  ]
}
