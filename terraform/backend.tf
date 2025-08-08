# Terraform S3 Backend Configuration - COMMENTED OUT FOR TESTING
# This stores the Terraform state file in S3 with DynamoDB locking
# for team collaboration and state safety

# terraform {
#   backend "s3" {
#     bucket         = "terraform-state-ec2-user-provisioning"
#     key            = "ec2-user-provisioning/terraform.tfstate"
#     region         = "us-east-2"
#     dynamodb_table = "terraform-state-lock"
#     encrypt        = true
#     
#     # Optional: Add server-side encryption with KMS
#     # kms_key_id = "arn:aws:kms:us-east-2:ACCOUNT_ID:key/KEY_ID"
#     
#     # Note: Versioning is enabled on the S3 bucket itself, not here
#   }
# }

# Note: S3 backend is disabled for testing the S3 key management functionality
# Enable this after testing is complete by uncommenting the terraform block above
