locals {
  aws_region            = "us-east-1"
  project_name          = "ironcore"

  # Reads env.hcl from the directory where terragrunt was executed
  env_vars             = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env                  = local.env_vars.locals.env

  # Environment-Aware State Resources
  state_s3_bucket       = "${local.project_name}-terraform-state-${local.env}"
  state_dynamodb_table  = "${local.project_name}-terraform-state-locks-${local.env}"
  state_key_prefix      = "s3"
}

# ==========================================
# Expose Global Inputs to Child Modules
# ==========================================
inputs = {
  aws_region           = local.aws_region
  project_name         = local.project_name
  env                  = local.env
  state_s3_bucket      = local.state_s3_bucket
  state_dynamodb_table = local.state_dynamodb_table
}

# ==========================================
# Generate AWS Provider
# ==========================================
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"
}
EOF
}

# ==========================================
# Generate Static AWS S3 Backend
# ==========================================
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