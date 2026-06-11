variable "region" {
  description = "AWS region for the backend"
  type        = string
  default     = "us-east-1"
}

variable "profile" {
  description = "AWS CLI profile"
  type        = string
  default     = "dev-sso"
}

variable "bucket_name" {
  description = "S3 bucket name for Terraform state"
  type        = string
}

variable "lock_table_name" {
  description = "DynamoDB table name for Terraform locks"
  type        = string
}


variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
