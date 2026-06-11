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
  source = "../../../modules/1-vpc"
}

inputs = {
  env        = include.env.locals.env
  region     = include.root.locals.aws_region
  vpc_name  = "${include.root.locals.project_name}-${include.env.locals.env}"
  vpc_cidr = "10.10.0.0/16"
  cluster_name = "${include.root.locals.project_name}-${include.env.locals.env}"

  azs = [
    "${include.root.locals.aws_region}a",
    "${include.root.locals.aws_region}b"
  ]

  private_subnets = ["10.10.1.0/24", "10.10.2.0/24"]
  public_subnets  = ["10.10.101.0/24", "10.10.102.0/24"]
  intra_subnets   = ["10.10.201.0/24", "10.10.202.0/24"]

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = {
    Terraform   = "true"
    Environment = include.env.locals.env
  }

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
}
