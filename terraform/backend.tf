# Terraform backend configuration
# Using local backend for simplicity and reliability

# Local backend (default) - no configuration needed
# State will be stored in terraform.tfstate file

# S3 backend configuration (commented out for now)
# Uncomment and configure when you want to use S3 for state storage
#
# terraform {
#   backend "s3" {
#     bucket         = "your-terraform-state-bucket"
#     key            = "ec2-user-provisioning/terraform.tfstate"
#     region         = "us-east-2"
#     dynamodb_table = "terraform-state-lock"
#     encrypt        = true
#   }
# }
