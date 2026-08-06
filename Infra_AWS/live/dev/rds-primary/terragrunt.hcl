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

# 🌟 Automatically generates a Terraform file that saves the random secret ARN into SSM
generate "ssm_pointer" {
  path      = "ssm_pointer.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
resource "aws_ssm_parameter" "rds_secret_arn" {
  name  = "/${include.root.locals.project_name}/${include.env.locals.env}/rds_secret_arn"
  type  = "String"
  value = module.db_instance.db_instance_master_user_secret_arn
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

  # AWS automatically creates and manages secret in Secrets Manager
  manage_master_user_password = true

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