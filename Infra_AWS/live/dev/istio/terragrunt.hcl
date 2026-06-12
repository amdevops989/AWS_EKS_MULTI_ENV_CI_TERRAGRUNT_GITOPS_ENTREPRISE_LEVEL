include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  domains = "travelersources.com\\,api.travelersources.com"
}
dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    cluster_name           = "mock-cluster"
    cluster_endpoint       = "https://mock-cluster-endpoint"
    cluster_ca_certificate = "mock-ca-data"
    cluster_token          = "mock-token"
    cluster_security_group_id = "sg-5566336633665544"
    oidc_provider_arn      = "arn:aws:iam::123456789012:oidc-provider/mock"
    oidc_provider_url      = "https://oidc.mock.eks.amazonaws.com/id/ABC123"
  }

  mock_outputs_merge_with_state = true
}

terraform {
  source = "../../../modules/7-istio"
}

inputs = {
  cluster_name         = dependency.eks.outputs.cluster_name
  region               = include.root.locals.aws_region
  k8s_host             = dependency.eks.outputs.cluster_endpoint
  k8s_ca               = dependency.eks.outputs.cluster_ca_certificate
  k8s_token            = dependency.eks.outputs.cluster_token
  profile              = include.root.locals.aws_profile
  domain_filters       = local.domains
  cluster_security_group_id = dependency.eks.outputs.cluster_security_group_id
  
}
