###########################
# Namespace
###########################
resource "kubernetes_namespace_v1" "kafka" {
  metadata {
    name = "kafka"
  }
}

###########################
# Headless Service
###########################
resource "kubernetes_service_v1" "kafka" {
  metadata {
    name      = "kafka"
    namespace = kubernetes_namespace_v1.kafka.metadata[0].name
    labels = {
      app = "kafka"
    }
  }

  spec {
    cluster_ip = "None" # headless for StatefulSet

    selector = {
      app = "kafka"
    }

    port {
      name       = "broker"
      port       = 9092
      target_port = 9092
    }

    port {
      name       = "host"
      port       = 29092
      target_port = 29092
    }

    port {
      name       = "controller"
      port       = 9093
      target_port = 9093
    }
  }
}

###########################
# StatefulSet
###########################
resource "kubernetes_stateful_set_v1" "kafka" {
  metadata {
    name      = "kafka"
    namespace = kubernetes_namespace_v1.kafka.metadata[0].name
    labels = {
      app = "kafka"
    }
  }

  spec {
    service_name = kubernetes_service_v1.kafka.metadata[0].name
    replicas     = 1

    selector {
      match_labels = {
        app = "kafka"
      }
    }

    template {
      metadata {
        labels = {
          app = "kafka"
        }
      }

      spec {
        node_selector = {
          role = "main"
        }  ## to allow 

        security_context {
          run_as_user  = 1000
          run_as_group = 1000
          fs_group     = 1000
        }
        hostname  = "kafka-0"
        subdomain = "kafka"

        container {
          name  = "kafka"
          image = "apache/kafka:3.9.1"

          port {
            container_port = 9092
            name           = "broker"
          }

          port {
            container_port = 29092
            name           = "host"
          }

          port {
            container_port = 9093
            name           = "controller"
          }

          env {
            name  = "KAFKA_NODE_ID"
            value = "1"
          }

          env {
            name  = "KAFKA_PROCESS_ROLES"
            value = "broker,controller"
          }

          env {
            name  = "KAFKA_CONTROLLER_QUORUM_VOTERS"
            value = "1@kafka-0.kafka.kafka.svc.cluster.local:9093"
          }

          env {
            name  = "KAFKA_LISTENERS"
            value = "PLAINTEXT://0.0.0.0:9092,PLAINTEXT_HOST://0.0.0.0:29092,CONTROLLER://0.0.0.0:9093"
          }

          env {
            name  = "KAFKA_ADVERTISED_LISTENERS"
            value = "PLAINTEXT://kafka-0.kafka.kafka.svc.cluster.local:9092,PLAINTEXT_HOST://localhost:29092"
          }

          env {
            name  = "KAFKA_LISTENER_SECURITY_PROTOCOL_MAP"
            value = "PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT,CONTROLLER:PLAINTEXT"
          }

          env {
            name  = "KAFKA_INTER_BROKER_LISTENER_NAME"
            value = "PLAINTEXT"
          }

          env {
            name  = "KAFKA_CONTROLLER_LISTENER_NAMES"
            value = "CONTROLLER"
          }

          env {
            name  = "KAFKA_LOG_DIRS"
            value = "/var/lib/kafka/data/kraft-combined-logs"
          }

          env {
            name  = "KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR"
            value = "1"
          }

          env {
            name  = "KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR"
            value = "1"
          }

          env {
            name  = "KAFKA_TRANSACTION_STATE_LOG_MIN_ISR"
            value = "1"
          }

          env {
            name  = "KAFKA_MIN_INSYNC_REPLICAS"
            value = "1"
          }

          env {
            name  = "KAFKA_AUTO_CREATE_TOPICS_ENABLE"
            value = "true"
          }

          env {
            name  = "KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS"
            value = "0"
          }

          volume_mount {
            name       = "kafka-data"
            mount_path = "/var/lib/kafka/data"
          }
        }
      }
    }
    volume_claim_template {
      metadata {
        name = "kafka-data"
      }

      spec {
        access_modes = ["ReadWriteOnce"]

        resources {
          requests = {
            storage = "1Gi"
          }
        }

        storage_class_name = "gp3-default"
      }
    }
  }
}
