
variable "region" {
  type        = string
  description = "AWS region"
}

variable "profile" {
  type        = string
  description = "AWS CLI profile"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "k8s_host" {
  type        = string
  description = "Kubernetes cluster endpoint"
}

variable "k8s_ca" {
  type        = string
  description = "Base64-encoded Kubernetes CA"
}

variable "k8s_token" {
  type        = string
  description = "Kubernetes Bearer token"
}

variable "cluster_security_group_id" {
  type        = string
}


variable "domain_filters" {
  description = "List of domains for external-dns"
  type        = string
  # default     = "travelersources.com\\,api.travelersources.com"
}

# kubectl patch svc gateway -n istio-ingress \
#   -p '{"metadata": {"annotations": {"external-dns.alpha.kubernetes.io/hostname": "travelersources.com,api.travelersources.com,frontend.travelersources.com"}}}'

# kubectl patch svc gateway -n istio-ingress \
#   -p '{"metadata": {"annotations": {"external-dns.alpha.kubernetes.io/hostname": "travelersources.com,api.travelersources.com,frontend.travelersources.com,test.travelersources.com"}}}'
