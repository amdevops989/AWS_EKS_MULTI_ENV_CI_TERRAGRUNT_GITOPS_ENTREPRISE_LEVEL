output "db_instance_arn" {
  description = "The ARN of the primary database instance"
  value       = module.db_instance.db_instance_arn
}

output "db_instance_endpoint" {
  description = "The connection endpoint for the database instance"
  value       = module.db_instance.db_instance_endpoint
}