
#### Cloud Config

# provider "kubernetes" {
#   host                   = var.k8s_host
#   cluster_ca_certificate = base64decode(var.k8s_ca)

#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "aws"
#     args        = [
#       "eks", "get-token",
#       "--cluster-name", var.cluster_name,
#       "--region", var.region,
#       "--profile", var.profile
#     ]
#   }
# }

# provider "helm" {
#   kubernetes {
#     host                   = var.k8s_host
#     cluster_ca_certificate = base64decode(var.k8s_ca)

#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       command     = "aws"
#       args        = [
#         "eks", "get-token",
#         "--cluster-name", var.cluster_name,
#         "--region", var.region,
#         "--profile", var.profile
#       ]
#     }
#   }
# }

# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 5.0"
#     }
#     kubernetes = {
#       source  = "hashicorp/kubernetes"
#       version = "~> 2.20"
#     }
#     helm = {
#       source  = "hashicorp/helm"
#       version = "~> 2.10"
#     }
#   }
#   backend "s3" {
    
#   }
# }

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }
  }
}

provider "kubernetes" {
  config_path = pathexpand("~/.kube/config") # minikube's kubeconfig
}

provider "helm" {
  kubernetes {
    config_path = pathexpand("~/.kube/config")
  }
}


