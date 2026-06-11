# curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
# chmod +x kubectl-argo-rollouts-linux-amd64
# sudo mv kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts


# helm upgrade --install argo-rollouts argo/argo-rollouts \
#   --namespace argo-rollouts --create-namespace \
#   --set dashboard.enabled=true
# -----------------------------
# Namespace with Prometheus labels
# -----------------------------
resource "kubernetes_namespace" "argo_rollouts" {
  metadata {
    name = "argo-rollouts"
    labels = {
      release = "kube-prom-stack"  # label Prometheus will detect
    }
  }
}

# -----------------------------
# Helm Release for Argo Rollouts
# -----------------------------
resource "helm_release" "argo_rollouts" {
  name       = "argo-rollouts"
  namespace  = kubernetes_namespace.argo_rollouts.metadata[0].name
  create_namespace = false   # already created via kubernetes_namespace
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-rollouts"
  version    = "2.40.5"

  set {
    name  = "controller.replicaCount"
    value = "1"
  }

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "dashboard.enabled"
    value = "true"
  }

  set {
    name  = "controller.metrics.enabled"
    value = "true"
  }

  set {
    name  = "controller.metrics.serviceMonitor.enabled"
    value = "true"
  }

  # -----------------------------
  # Force pods on main node group
  # -----------------------------
  # set {
  #   name  = "controller.nodeSelector.role"
  #   value = "main"
  # }

  # set {
  #   name  = "dashboard.nodeSelector.role"
  #   value = "main"
  # }
}
