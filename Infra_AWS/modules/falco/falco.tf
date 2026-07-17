resource "helm_release" "falco" {
  name       = "falco"
  namespace  = "falco"
  repository = "https://falcosecurity.github.io/charts"
  chart      = "falco"
  version    = "4.7.1" # stable, compatible with Falco >= 0.43

  create_namespace = true

  values = [
    yamlencode({
      driver = {
        kind = "ebpf" # ✅ BEST for EKS
      }

      daemonset = {
        privileged = true
      }

      falco = {
        json_output = true
        json_include_output_property = true
      }

      falcosidekick = {
        enabled = true

        webui = {
          enabled = true
        }
      }
    })
  ]
}

