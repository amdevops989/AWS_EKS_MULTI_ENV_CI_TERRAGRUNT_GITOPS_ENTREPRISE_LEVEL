resource "helm_release" "postgres" {
  name      = "my-postgresql"
  namespace = kubernetes_namespace_v1.postgres.metadata[0].name

  chart   = "oci://registry-1.docker.io/bitnamicharts/postgresql"
  version = "18.2.3"

  values = [
    file("${path.module}/values/values-postgres.yml")
  ]

  depends_on = [
    kubernetes_namespace_v1.postgres,
    kubernetes_config_map_v1.postgres_init_sql
  ]
}
