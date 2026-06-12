terraform {
  required_version = ">= 1.0.0"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0.0"
    }
    
  }
}


provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "minikube"
}

provider "helm" {
  kubernetes = {
    config_path    = "~/.kube/config"
    config_context = "minikube"
  }
}

resource "null_resource" "minikube_lifecycle" {
  # This triggers the exact native minikube CLI command you provided
  provisioner "local-exec" {
    command = "minikube start --addons volumesnapshots,csi-hostpath-driver --apiserver-port=6443 --container-runtime=containerd --memory=4096 --cpus=2"
  }

  # Ensures clean destruction when running 'terraform destroy'
  provisioner "local-exec" {
    when    = destroy
    command = "minikube delete"
  }
}