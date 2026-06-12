resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "6.7.18"

  create_namespace = true

  values = [
    yamlencode({
      server = {
        service = {
          type = "ClusterIP"
        }
        extraArgs = ["--insecure"]
        # nodeSelector = {
        #   role = "main"
        # }
      }

      repoServer = {
        # nodeSelector = {
        #   role = "main"
        # }
      }

      applicationController = {
        # nodeSelector = {
        #   role = "main"
        # }
      }

      dex = {
        # nodeSelector = {
        #   role = "main"
        # }
      }
    })
  ]
}
