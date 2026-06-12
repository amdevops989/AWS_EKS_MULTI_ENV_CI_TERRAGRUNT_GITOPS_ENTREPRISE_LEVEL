locals {
  aws_region   = "us-east-1"
  project_name = "vanguardyouth"
  
  # If running in GitHub Actions, pass an empty string for the profile 
  # so Terraform falls back to the OIDC environment variables automatically.
  aws_profile  = get_env("GITHUB_ACTIONS", "false") == "true" ? "" : "devops-dev"
}

# ===============================#
# Global Inputs
# ===============================
inputs = {
  aws_region   = local.aws_region
  aws_profile  = local.aws_profile
  project_name = local.project_name
}




# ===============================
# Generate AWS Provider
# ===============================
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region  = "${local.aws_region}"
  profile = "${local.aws_profile}"
}
EOF
}

# ===============================
# Generate Terraform Backend
# ===============================
generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  backend "s3" {
    bucket         = "${local.project_name}-tfstate"
    key            = "eks/${path_relative_to_include()}/terraform.tfstate"
    region         = "${local.aws_region}"
    dynamodb_table = "${local.project_name}-tf-locks"
    ${local.aws_profile != "" ? "profile = \"${local.aws_profile}\"" : ""}
    encrypt        = true
  }
}
EOF
}

