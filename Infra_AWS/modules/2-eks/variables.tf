###############################################################################
# Global
###############################################################################

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
}

###############################################################################
# Networking
###############################################################################

variable "vpc_id" {
  description = "VPC ID where EKS will be deployed"
  type        = string
}

variable "private_subnets" {
  description = "Private subnet IDs for worker nodes"
  type        = list(string)
}

variable "intra_subnets" {
  description = "Intra / control plane subnet IDs"
  type        = list(string)
}

###############################################################################
# Node Group (EKS Managed Node Group for Karpenter bootstrap)
###############################################################################

variable "node_instance_type" {
  description = "Instance types for the EKS managed node group"
  type        = list(string)
}

variable "node_min_capacity" {
  description = "Minimum number of nodes"
  type        = number
}

variable "node_max_capacity" {
  description = "Maximum number of nodes"
  type        = number
}

variable "node_desired_capacity" {
  description = "Desired number of nodes"
  type        = number
}

###############################################################################
# Node Storage
###############################################################################

variable "volume_size" {
  description = "Root EBS volume size in GiB"
  type        = number
}

variable "volume_type" {
  description = "EBS volume type"
  type        = string
  default     = "gp3"
}

###############################################################################
# Tags
###############################################################################

variable "tags" {
  description = "Tags applied to all EKS resources"
  type        = map(string)
  default     = {}
}


variable "env" {
  type        = string
}