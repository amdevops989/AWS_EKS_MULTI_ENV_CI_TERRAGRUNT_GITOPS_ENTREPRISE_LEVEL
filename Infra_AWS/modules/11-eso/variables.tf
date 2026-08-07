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

# variable "k8s_token" {
#   type        = string
#   description = "Kubernetes Bearer token"
# }

variable "role_name" {
  type        = string
  description = "Name of the IAM role for ESO"
}

variable "oidc_provider_arn" {
  type        = string
  description = "ARN of the EKS OIDC provider"
}
variable "oidc_provider_url" {
  type        = string
  description = "URL of the EKS OIDC provider"
}
variable "namespace" {
  type        = string
  default     = "external-secrets"
  description = "Namespace for ESO"
}

variable "service_account_name" {
  type        = string
  default     = "external-secrets"
  description = "Name of the Service Account"
}

variable "chart_version" {
  type        = string
  default     = "0.9.13"
  description = "Helm chart version"
}

variable "tags" {
  type        = map(string)
  default     = {}
}

variable "env" {
  type        = string
  default     = ""
  description = "description"
}
