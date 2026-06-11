resource "kubernetes_config_map_v1" "postgres_init_sql" {
  metadata {
    name      = "postgres-init-sql"
    namespace = kubernetes_namespace_v1.postgres.metadata[0].name
  }

  data = {
    "init-db.sql" = file("${path.module}/sql/init-db.sql")
  }
}
