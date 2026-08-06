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
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-route53.git//modules/records?ref=v3.1.0"
}

dependency "phz" {
  config_path = "../route53-private-db"

  mock_outputs = {
    route53_zone_zone_id = {
      "internal.vanguardyouth.store" = "Z1111111111111"
    }
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-validate"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

# 🌟 Fetch Primary RDS Endpoint
dependency "rds_primary" {
  config_path = "../rds-primary"

  mock_outputs = {
    db_instance_address = "vanguard-primary.c1234567890.us-east-1.rds.amazonaws.com"
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-validate"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

inputs = {
  zone_id = dependency.phz.outputs.route53_zone_zone_id["internal.vanguardyouth.store"]

  records = [
    {
      name = "db" # Creates db.internal.vanguardyouth.store
      type = "CNAME"
      ttl  = 5
      records = [
        element(split(":", dependency.rds_primary.outputs.db_instance_endpoint), 0)
      ]
    }
  ]
}