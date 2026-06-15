resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      monitoring = "prometheus"
    }
  }
}

resource "helm_release" "kube_prom_stack" {
  name       = "kube-prom-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  create_namespace = false

  values = [
    file("${path.module}/values.yaml")
  ]

  depends_on = [
    kubernetes_namespace.monitoring,
    null_resource.alertmanager_slack
  ]
}



