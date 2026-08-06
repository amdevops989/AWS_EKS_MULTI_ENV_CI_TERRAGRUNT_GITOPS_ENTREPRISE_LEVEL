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

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id = "vpc-dr-67890"
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-validate"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

inputs = {
  zones = {
    "dr.internal.vanguardyouth.store" = {
      comment = "Private hosted zone for DR VPC services"
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