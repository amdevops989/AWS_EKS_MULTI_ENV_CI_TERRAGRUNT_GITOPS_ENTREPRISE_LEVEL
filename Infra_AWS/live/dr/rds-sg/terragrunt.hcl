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
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-security-group.git?ref=v5.1.0"
}

# Fetch DR VPC Outputs
dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id         = "vpc-87654321"
    vpc_cidr_block = "10.20.0.0/16"
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-validate", "apply", "destroy"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

inputs = {
  name        = "${include.root.locals.project_name}-${include.env.locals.env}-replica-rds-sg"
  description = "Security group for DR PostgreSQL RDS Replica"
  vpc_id      = dependency.vpc.outputs.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from DR VPC"
      cidr_blocks = dependency.vpc.outputs.vpc_cidr_block
    }
  ]
  
  tags = {
    Terraform   = "true"
    Environment = include.env.locals.env
  }
}