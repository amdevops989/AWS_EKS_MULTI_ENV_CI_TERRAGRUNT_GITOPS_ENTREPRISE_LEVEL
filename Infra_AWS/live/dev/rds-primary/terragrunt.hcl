include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

include "env" {
  path           = find_in_parent_folders("env.hcl")
  expose         = true
  merge_strategy = "no_merge"
}

terraform {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-rds.git?ref=v6.3.0"
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    private_subnet_ids = ["subnet-11111111", "subnet-22222222"]
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-validate", "apply", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

dependency "rds_sg" {
  config_path = "../rds-sg"
  mock_outputs = {
    security_group_id = "sg-999999999"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-validate", "apply", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

# 🌟 1. Standard Terraform file for new resource creation (NO _override suffix)
generate "predictable_secret" {
  path      = "predictable_secret.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
resource "random_password" "master_password" {
  length  = 24
  special = false
}

resource "aws_secretsmanager_secret" "rds_credentials" {
  name                    = "${include.root.locals.project_name}/${include.env.locals.env}/rds-cred"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id     = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username = "dbadmin"
    password = random_password.master_password.result
    dbname   = "vanguardyouth"
    port     = "5432"
  })
}
EOF
}

# 🌟 2. Separate override file reserved STRICTLY for overriding the module invocation
generate "module_override" {
  path      = "module_override.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
module "db_instance" {
  password = random_password.master_password.result
}
EOF
}

inputs = {
  aws_region = include.root.locals.aws_region

  identifier = "${include.root.locals.project_name}-${include.env.locals.env}-primary-db"

  engine                = "postgres"
  engine_version        = "15.8"
  family                = "postgres15"
  instance_class        = "db.t4g.micro"
  allocated_storage     = 20
  max_allocated_storage = 100

  db_name  = "vanguardyouth"
  username = "dbadmin"

  manage_master_user_password = false

  port                    = 5432
  backup_retention_period = 7
  deletion_protection     = false

  create_db_subnet_group = true
  subnet_ids             = dependency.vpc.outputs.private_subnet_ids

  vpc_security_group_ids = [dependency.rds_sg.outputs.security_group_id]

  create_db_parameter_group = true
  parameter_group_name      = "${include.root.locals.project_name}-${include.env.locals.env}-pg15-params"

  tags = {
    Terraform   = "true"
    Environment = include.env.locals.env
  }
}