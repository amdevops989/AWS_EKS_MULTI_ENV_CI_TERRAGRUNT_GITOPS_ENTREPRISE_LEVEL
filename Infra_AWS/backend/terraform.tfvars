region = "us-east-1"

profile = "devops-dev"

bucket_name = "vanguardyouth-tfstate"

lock_table_name = "vanguardyouth-tf-locks"

tags = {
  Environment = "dev"
  Project     = "eks-platform"
  Owner       = "devops-team"
  ManagedBy   = "terraform"
}