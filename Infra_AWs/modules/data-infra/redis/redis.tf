# ------------------------------
# Namespace
# ------------------------------
resource "kubernetes_namespace_v1" "redis" {
  metadata {
    name = "redis"
  }
}

# ------------------------------
# Redis Helm Release
# ------------------------------
resource "helm_release" "redis" {
  name       = "redis"
  namespace  = kubernetes_namespace_v1.redis.metadata[0].name
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "redis"
  version    = "24.1.2"

  values = [
    yamlencode({
      global = {
        security = {
          allowInsecureImages = true
        }
      }

      architecture = "standalone"

      auth = {
        enabled = false
      }

      replica = {
        replicaCount = 0
      }

      master = {
        nodeSelector = {       
          role = "main"
        }
        persistence = {
          enabled       = true   # keep PVC enabled for master
          size          = "1Gi"
          storageClass  = "gp3-default"
        }
      }

      service = {
        type = "ClusterIP"   # <-- internal only
        port = 6379
      }

    })
  ]

  depends_on = [
    kubernetes_namespace_v1.redis
  ]
}
