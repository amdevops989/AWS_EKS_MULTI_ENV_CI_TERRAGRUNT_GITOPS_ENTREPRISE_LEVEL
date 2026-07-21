variable "env" {
  description = "Target environment (e.g., dev, prod)"
  type        = string
}

variable "region" {
  description = "AWS Region"
  type        = string
}

variable "tags" {
  description = "Map of resource tags"
  type        = map(string)
  default     = {}
}

variable "bucket_name_prefix" {
  description = "Prefix for the S3 bucket name"
  type        = string
  default     = "ironcore-data"
}