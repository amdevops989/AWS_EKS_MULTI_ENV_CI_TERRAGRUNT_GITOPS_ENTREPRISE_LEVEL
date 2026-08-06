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
      "dr.internal.vanguardyouth.store" = "Z2222222222222"
    }
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-validate"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

dependency "rds_replica" {
  config_path = "../rds-replica"

  mock_outputs = {
    db_instance_address = "ironcore-dr-replica-db.c123456789012.us-west-2.rds.amazonaws.com"
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-validate"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

inputs = {
  zone_id = dependency.phz.outputs.route53_zone_zone_id["dr.internal.vanguardyouth.store"]

  records = [
    {
      name = "db" # Resolves to db.dr.internal.vanguardyouth.store
      type = "CNAME"
      ttl  = 5
      records = [
        dependency.rds_replica.outputs.db_instance_address
      ]
    }
  ]
}