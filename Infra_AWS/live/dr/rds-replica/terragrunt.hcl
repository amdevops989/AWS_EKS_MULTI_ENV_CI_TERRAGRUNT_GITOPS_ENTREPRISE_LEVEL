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

# 🌟 Fetch Primary DB Outputs
dependency "primary_db" {
  config_path = "../../dev/rds-primary"

  mock_outputs = {
    db_instance_arn      = "arn:aws:rds:us-east-1:123456789012:db:vanguardyouth-dev-primary-db"
    db_instance_endpoint = "db.internal.vanguardyouth.store:5432"
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

# 🌟 Fetch DR Security Group ID
dependency "rds_sg" {
  config_path = "../rds-sg"

  mock_outputs = {
    security_group_id = "sg-888888888"
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-validate"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

# 🌟 Replicate Primary Secret (vanguardyouth/dev/rds-cred) into DR Region (vanguardyouth/dr/rds-cred)
generate "predictable_secret" {
  path      = "predictable_secret.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
# Read updated primary secret from us-east-1 using the aws.virginia provider
data "aws_secretsmanager_secret" "primary" {
  provider = aws.virginia
  name     = "${include.root.locals.project_name}/dev/rds-cred"
}

data "aws_secretsmanager_secret_version" "primary" {
  provider  = aws.virginia
  secret_id = data.aws_secretsmanager_secret.primary.id
}

# Create matching local secret entry in DR region
resource "aws_secretsmanager_secret" "dr_rds_credentials" {
  name                    = "${include.root.locals.project_name}/${include.env.locals.env}/rds-cred"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "dr_rds_credentials" {
  secret_id     = aws_secretsmanager_secret.dr_rds_credentials.id
  secret_string = data.aws_secretsmanager_secret_version.primary.secret_string
}
EOF
}

inputs = {
  aws_region = include.root.locals.aws_region

  identifier          = "${include.root.locals.project_name}-${include.env.locals.env}-replica-db"
  replicate_source_db = dependency.primary_db.outputs.db_instance_arn

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

  create_db_security_group = false
  vpc_security_group_ids   = [dependency.rds_sg.outputs.security_group_id]

  tags = {
    Terraform   = "true"
    Environment = include.env.locals.env
  }
}