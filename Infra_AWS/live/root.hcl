locals {
  project_name = "vanguardyouth"
  profile      = "devops"

  aws_account_id = get_aws_account_id()

  # Reads env.hcl dynamically (Ensure aws_region in env.hcl is set to "us-west-1")
  env_vars   = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env        = local.env_vars.locals.env
  aws_region = local.env_vars.locals.aws_region # "us-west-1"

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
# Primary Provider for us-west-1
provider "aws" {
  region  = "${local.aws_region}"
  profile = "${local.profile}"
}

# Secondary Provider strictly for Public ECR Tokens (Must be us-east-1)
provider "aws" {
  alias   = "virginia"
  region  = "us-east-1"
  profile = "${local.profile}"
}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
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