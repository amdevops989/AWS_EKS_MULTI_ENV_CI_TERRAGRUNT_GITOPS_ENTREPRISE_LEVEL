resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = "3.13.0"

  # set {
  #   name  = "nodeSelector.eks\\.amazonaws\\.com/nodegroup"
  #   value = keys(module.eks.eks_managed_node_groups)[0]
  # }

  values = [
    file("${path.module}/metrics-values.yaml")
  ]

  depends_on = [
    module.eks
  ]
}
