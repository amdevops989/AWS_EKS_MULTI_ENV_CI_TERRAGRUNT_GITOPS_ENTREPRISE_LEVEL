
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


variable "slack_webhook_url" {
  description = "Slack Incoming Webhook URL for Alertmanager"
  type        = string
  sensitive   = true
}