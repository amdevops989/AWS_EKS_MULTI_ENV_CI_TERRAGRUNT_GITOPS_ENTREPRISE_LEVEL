output "db_instance_arn" {
  description = "The ARN of the DR database replica instance"
  value       = module.db_instance.db_instance_arn
}

output "db_instance_address" {
  description = "The hostname address of the DR database replica (without port)"
  value       = module.db_instance.db_instance_address
}

output "db_instance_endpoint" {
  description = "The connection endpoint for the DR database replica (hostname:port)"
  value       = module.db_instance.db_instance_endpoint
}

# 🌟 FIXED: Use db_instance_identifier instead of db_instance_id
output "db_instance_id" {
  description = "The RDS instance identifier"
  value       = module.db_instance.db_instance_identifier
}

output "db_instance_port" {
  description = "The database port"
  value       = module.db_instance.db_instance_port
}