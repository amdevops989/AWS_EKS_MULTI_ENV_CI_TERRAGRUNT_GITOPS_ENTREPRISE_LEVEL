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

# Fetch VPC Outputs from ../vpc
dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id         = "vpc-12345678"
    vpc_cidr_block = "10.10.0.0/16"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-validate", "destroy", "apply"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

# Fetch EKS Outputs from ../eks
dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    node_security_group_id = "sg-0123456789abcdef0"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-validate", "destroy", "apply"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

inputs = {
  name        = "${include.root.locals.project_name}-${include.env.locals.env}-rds-sg"
  description = "Security group for PostgreSQL RDS"
  vpc_id      = dependency.vpc.outputs.vpc_id

  # Allow all EKS Pods in the VPC to access PostgreSQL
  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from VPC CIDR"
      cidr_blocks = dependency.vpc.outputs.vpc_cidr_block
    }
  ]
  
  # Allow traffic originating directly from the EKS Node Security Group
  ingress_with_source_security_group_id = [
    {
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      description              = "PostgreSQL access from EKS Nodes"
      source_security_group_id = dependency.eks.outputs.node_security_group_id
    }
  ]

    tags = {
    Terraform   = "true"
    Environment = include.env.locals.env
  }
}