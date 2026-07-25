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

# 🌟 Fetch VPC Outputs from 1-vpc
dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id             = "vpc-12345678"
    private_subnet_ids = ["subnet-11111111", "subnet-22222222"] # FIXED key name
    vpc_cidr_block     = "10.10.0.0/16"
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-validate"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

inputs = {
  aws_region = include.root.locals.aws_region

  identifier = "${include.root.locals.project_name}-${include.env.locals.env}-primary-db"

  engine               = "postgres"
  engine_version       = "15.8"
  family               = "postgres15"
  instance_class       = "db.t4g.micro"
  allocated_storage    = 20
  max_allocated_storage = 100

  db_name  = "ironcore"
  username = "dbadmin"
  
  # 🌟 Disable AWS Managed Secrets Manager Password
  manage_master_user_password = false
  password                    = "YourSecretPassword123!" # Pass via SOPS / environment variable in prod

  port     = "5432"

  backup_retention_period = 7
  deletion_protection     = false

  create_db_subnet_group = true
  subnet_ids             = dependency.vpc.outputs.private_subnet_ids

  create_db_security_group = true
  vpc_id                   = dependency.vpc.outputs.vpc_id
  allowed_cidr_blocks      = [dependency.vpc.outputs.vpc_cidr_block]

  tags = {
    Terraform   = "true"
    Environment = include.env.locals.env
  }
}