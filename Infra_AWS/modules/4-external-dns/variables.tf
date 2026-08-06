variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "env" {
  type        = string
  default     = ""
  description = "Environment name (e.g., dev, staging, prod)"
}

variable "k8s_namespace" {
  type        = string
  default     = "kube-system"
  description = "Namespace for ExternalDNS"
}

variable "service_account_name" {
  type        = string
  default     = "external-dns"
}

variable "oidc_provider_arn" {
  type        = string
  description = "OIDC provider ARN for EKS"
}

variable "oidc_provider_url" {
  type        = string
  description = "OIDC provider URL for EKS"
}

variable "domain_filters" {
  type        = list(string)
  description = "Domains that ExternalDNS should manage"
}

variable "zone_type" {
  type        = string
  default     = "public"
}

variable "hosted_zone_id" {
  type        = string
  description = "Route53 hosted zone ID for ExternalDNS"
}

variable "helm_chart_version" {
  type        = string
  default     = "1.19.0"
}

# 🌟 NEW VARIABLES FOR MULTI-ENV & ISTIO SUPPORT
variable "sources" {
  type        = list(string)
  default     = ["service", "ingress", "istio-gateway", "istio-virtualservice"]
  description = "List of K8s / Istio resources ExternalDNS monitors"
}

variable "txt_owner_id" {
  type        = string
  default     = ""
  description = "Unique ID for Route53 TXT records ownership per cluster"
}

variable "txt_prefix" {
  type        = string
  default     = "site-k8s-"
  description = "Prefix for Route53 TXT record ownership keys"
}

variable "k8s_host" {
  type = string
}

variable "k8s_ca" {
  type = string
}

variable "k8s_token" {
  type = string
}

variable "profile" {
  type    = string
  default = ""
}