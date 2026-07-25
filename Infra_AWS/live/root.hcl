locals {
  project_name = "ironcore"
  profile      = "devops"

  # 🌟 Pure dynamic lookup via AWS STS GetCallerIdentity
  aws_account_id = get_aws_account_id()

  # Reads env.hcl dynamically
  env_vars   = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env        = local.env_vars.locals.env
  aws_region = local.env_vars.locals.aws_region

  state_s3_bucket      = "${local.project_name}-terraform-state-${local.env}-${local.aws_region}"
  state_dynamodb_table = "${local.project_name}-terraform-state-locks-${local.env}"
  state_key_prefix     = "s3"
}

inputs = {
  aws_region           = local.aws_region
  aws_account_id       = local.aws_account_id
  project_name         = local.project_name
  state_s3_bucket      = local.state_s3_bucket
  state_dynamodb_table = local.state_dynamodb_table
  profile              = local.profile
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region  = "${local.aws_region}"
  profile = "${local.profile}"
}
EOF
}

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  backend "s3" {
    bucket         = "${local.state_s3_bucket}"
    key            = "${local.state_key_prefix}/${path_relative_to_include()}/terraform.tfstate"
    region         = "${local.aws_region}"
    dynamodb_table = "${local.state_dynamodb_table}"
    encrypt        = true
  }
}
EOF
}