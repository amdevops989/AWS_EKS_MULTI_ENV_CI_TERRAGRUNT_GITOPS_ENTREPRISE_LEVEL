# ------------------------------
# Namespace
# ------------------------------
resource "kubernetes_namespace_v1" "debezium" {
  metadata {
    name = "debezium"
  }
}

# ------------------------------
# Debezium Connect Service
# ------------------------------
resource "kubernetes_service_v1" "debezium_connect" {
  metadata {
    name      = "debezium-connect"
    namespace = kubernetes_namespace_v1.debezium.metadata[0].name
    labels = {
      app = "debezium-connect"
    }
  }

  spec {
    type = "NodePort"

    selector = {
      app = "debezium-connect"
    }

    port {
      port        = 8083
      target_port = 8083
      node_port   = 30083
    }
  }

  depends_on = [
    kubernetes_namespace_v1.debezium
  ]
}

# ------------------------------
# Debezium Connect Deployment
# ------------------------------
resource "kubernetes_deployment_v1" "debezium_connect" {
  metadata {
    name      = "debezium-connect"
    namespace = kubernetes_namespace_v1.debezium.metadata[0].name
    labels = {
      app = "debezium-connect"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "debezium-connect"
      }
    }

    template {
      metadata {
        labels = {
          app = "debezium-connect"
        }
      }

      spec {
        container {
          name  = "connect"
          image = "debezium/connect:2.6"

          port {
            container_port = 8083
          }

          env {
            name  = "BOOTSTRAP_SERVERS"
            value = "kafka.kafka.svc.cluster.local:9092"
          }

          env {
            name  = "GROUP_ID"
            value = "debezium"
          }

          env {
            name  = "CONFIG_STORAGE_TOPIC"
            value = "connect-configs"
          }

          env {
            name  = "OFFSET_STORAGE_TOPIC"
            value = "connect-offsets"
          }

          env {
            name  = "STATUS_STORAGE_TOPIC"
            value = "connect-status"
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_namespace_v1.debezium,
    kubernetes_service_v1.debezium_connect
  ]
}
