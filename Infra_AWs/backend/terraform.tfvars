region = "us-east-1"

profile = "dev-sso"

bucket_name = "travelersources-tfstate"

lock_table_name = "travelersources-tf-locks"

tags = {
  Environment = "dev"
  Project     = "eks-platform"
  Owner       = "devops-team"
  ManagedBy   = "terraform"
}