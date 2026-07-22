include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}


//
include "env" {
  path           = find_in_parent_folders("env.hcl")
  expose         = true
  merge_strategy = "no_merge"
}

terraform {
  source = "../../../modules/s3"
}

inputs = {
  env        = include.env.locals.env
  region     = include.root.locals.aws_region
 

  tags = {
    Terraform   = "true"
    Environment = include.env.locals.env
  }

 
}
