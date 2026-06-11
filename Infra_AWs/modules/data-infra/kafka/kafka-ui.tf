# ------------------------------
# Kafka UI Deployment
# ------------------------------
resource "kubernetes_deployment_v1" "kafka_ui" {
  metadata {
    name      = "kafka-ui"
    namespace = kubernetes_namespace_v1.kafka.metadata[0].name
    labels = {
      app = "kafka-ui"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "kafka-ui"
      }
    }

    template {
      metadata {
        labels = {
          app = "kafka-ui"
        }
      }

      spec {
        # -------------------------------
        # Force pods to main node group
        # -------------------------------
        node_selector = {
          role = "main"
        }

        container {
          name  = "kafka-ui"
          image = "provectuslabs/kafka-ui:latest"

          port {
            container_port = 8080
            name           = "http"
          }

          env {
            name  = "KAFKA_CLUSTERS_0_NAME"
            value = "local-cluster"
          }

          env {
            name  = "KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS"
            value = "kafka:9092"
          }

          env {
            name  = "KAFKA_CLUSTERS_0_READONLY"
            value = "false"
          }

          env {
            name  = "KAFKA_CLUSTERS_0_TOPIC_AUTO_CREATE"
            value = "true"
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_stateful_set_v1.kafka
  ]
}

# ------------------------------
# Kafka UI Service (internal-only)
# ------------------------------
resource "kubernetes_service_v1" "kafka_ui" {
  metadata {
    name      = "kafka-ui"
    namespace = kubernetes_namespace_v1.kafka.metadata[0].name
    labels = {
      app = "kafka-ui"
    }
  }

  spec {
    type = "ClusterIP"  # internal-only
    selector = {
      app = "kafka-ui"
    }

    port {
      name        = "http"
      port        = 8080
      target_port = 8080
    }
  }

  depends_on = [
    kubernetes_deployment_v1.kafka_ui
  ]
}
