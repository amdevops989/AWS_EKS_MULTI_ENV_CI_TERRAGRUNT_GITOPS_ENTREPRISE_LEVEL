include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

include "env" {
  path           = find_in_parent_folders("env.hcl")
  expose         = true
  merge_strategy = "no_merge"
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id          = "vpc-123456"
    public_subnet_ids  = ["subnet-a","subnet-b"]
    private_subnet_ids = ["subnet-c","subnet-d"]
    intra_subnet_ids   = ["subnet-e","subnet-f"]

  }
  mock_outputs_merge_with_state = true
}

locals {
  cluster_name = "${include.root.locals.project_name}-${include.env.locals.env}"
}

terraform {
  source = "../../../modules/2-eks"
}

inputs = {
  cluster_name         = local.cluster_name
  region               = include.root.locals.aws_region
  profile              = include.root.locals.aws_profile
  env                  = include.env.locals.env
  project_name         = include.root.locals.project_name

  vpc_id               = dependency.vpc.outputs.vpc_id
  private_subnets      = dependency.vpc.outputs.private_subnet_ids
  intra_subnets        = dependency.vpc.outputs.intra_subnet_ids

  node_instance_type   = ["m5.large"]    # spot mode for dev and test
  node_desired_capacity = 1
  node_min_capacity     = 0
  node_max_capacity     = 1
  ssh_key_name          = ""
  # kms_key_arn           = "arn:aws:kms:us-east-1:272495906318:key/54e3bb98-a1ee-4d8f-86cb-308fbbfc56c9"
  # admin_roles           = [
  #   "arn:aws:iam::272495906318:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_AdministratorAccess_ad80597e4fb78530",
  #   "arn:aws:iam::272495906318:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_Eks-Admins_8a9129606b3cd370"
  # ]
  # developer_roles       = [
  #   "arn:aws:iam::272495906318:role/MyDeveloperRole"
  # ]
  tags = {
    Project     = include.root.locals.project_name
    Environment = include.env.locals.env
  }
  cluster_version = "1.33"  ## later use 1.33 or higher 
  volume_size = 30
  volume_type = "gp3"
  architecture = "x86_64"

}
