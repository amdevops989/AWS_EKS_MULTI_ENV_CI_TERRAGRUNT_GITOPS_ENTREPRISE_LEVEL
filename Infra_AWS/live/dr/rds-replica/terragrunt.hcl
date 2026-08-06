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

# 🌟 Fetch Primary DB ARN from DEV environment
dependency "primary_db" {
  config_path = "../../dev/rds-primary"

  mock_outputs = {
    db_instance_arn = "arn:aws:rds:us-east-1:123456789012:db:ironcore-dev-primary-db"
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-validate"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

# 🌟 Fetch DR VPC Outputs
dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id             = "vpc-87654321"
    private_subnet_ids = ["subnet-33333333", "subnet-44444444"]
    vpc_cidr_block     = "10.20.0.0/16"
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-validate"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

# 🌟 1. Fetch DR Security Group ID
dependency "rds_sg" {
  config_path = "../rds-sg"

  mock_outputs = {
    security_group_id = "sg-888888888"
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-validate"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

inputs = {
  aws_region = include.root.locals.aws_region

  identifier          = "${include.root.locals.project_name}-${include.env.locals.env}-replica-db"
  replicate_source_db = dependency.primary_db.outputs.db_instance_arn

  # 🌟 Disable AWS Managed Secrets Manager Password on replica
  manage_master_user_password = false

  storage_encrypted = true
  kms_key_id        = "arn:aws:kms:${include.root.locals.aws_region}:${include.root.locals.aws_account_id}:alias/aws/rds"

  engine         = "postgres"
  engine_version = "15.8"
  family         = "postgres15"
  instance_class = "db.t4g.micro"

  allocated_storage = 20

  create_db_subnet_group = true
  subnet_ids             = dependency.vpc.outputs.private_subnet_ids

  # 🌟 2. Link External Security Group instead of creating an inline SG
  create_db_security_group = false
  vpc_security_group_ids   = [dependency.rds_sg.outputs.security_group_id]

  tags = {
    Terraform   = "true"
    Environment = include.env.locals.env
  }
}