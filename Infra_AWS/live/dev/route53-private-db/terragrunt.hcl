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
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-route53.git//modules/zones?ref=v3.1.0"
}

# 🌟 Primary VPC Dependency
dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id = "vpc-primary-12345"
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-validate"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

inputs = {
  zones = {
    "internal.vanguardyouth.store" = {
      comment = "Private hosted zone for Primary VPC internal services"

      # 🌟 Associate with Primary VPC
      vpc = [
        {
          vpc_id = dependency.vpc.outputs.vpc_id
        }
      ]

      tags = {
        Environment = include.env.locals.env
        Terraform   = "true"
      }
    }
  }
}