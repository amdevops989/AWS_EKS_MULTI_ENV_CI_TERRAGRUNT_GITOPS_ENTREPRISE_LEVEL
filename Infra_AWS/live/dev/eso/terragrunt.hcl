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
  source = "../../../modules/11-eso"
}

dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    cluster_name           = "mock-cluster"
    cluster_endpoint       = "https://mock-cluster-endpoint"
    cluster_ca_certificate = "mock-ca-data"
    # cluster_token          = "mock-token"
    oidc_provider_arn      = "arn:aws:iam::123456789012:oidc-provider/mock"
    oidc_provider_url      = "https://oidc.mock.eks.amazonaws.com/id/ABC123"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-validate"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

# Inject dynamic Helm provider configuration for the destination cluster
# generate "providers" {
#   path      = "providers.tf"
#   if_exists = "overwrite_terragrunt"
#   contents  = <<EOF
# provider "helm" {
#   kubernetes {
#     host                   = "${dependency.eks.outputs.cluster_endpoint}"
#     cluster_ca_certificate = base64decode("${dependency.eks.outputs.cluster_certificate_authority_data}")
#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       args        = ["eks", "get-token", "--cluster-name", "${dependency.eks.outputs.cluster_name}"]
#       command     = "aws"
#     }
#   }
# }
# EOF
# }

inputs = {
  env                  = include.env.locals.env
  cluster_name         = dependency.eks.outputs.cluster_name
  region               = include.root.locals.aws_region
  k8s_host             = dependency.eks.outputs.cluster_endpoint
  k8s_ca               = dependency.eks.outputs.cluster_ca_certificate
  oidc_provider_url    = dependency.eks.outputs.oidc_provider_url
  role_name            = "${include.root.locals.project_name}-${include.env.locals.env}-eso-irsa"
  oidc_provider_arn    = dependency.eks.outputs.oidc_provider_arn
  namespace            = "external-secrets"
  service_account_name = "external-secrets"
  chart_version        = "0.9.13"

  tags = {
    Environment = include.env.locals.env
    Terraform   = "true"
  }
}