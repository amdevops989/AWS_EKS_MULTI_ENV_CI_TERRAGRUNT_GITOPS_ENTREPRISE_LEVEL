terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # version = "~> 5.0"
      version = ">= 6.28.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
    helm = {
    source  = "hashicorp/helm"
    version = "~> 2.10"
   }
  }
}
