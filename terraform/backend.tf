# Terraform S3 Backend Configuration
# This stores the Terraform state file in S3 with DynamoDB locking
# for team collaboration and state safety

terraform {
  backend "s3" {
    bucket         = "terraform-state-ec2-user-provisioning"
    key            = "ec2-user-provisioning/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
    
    # Optional: Add server-side encryption with KMS
    # kms_key_id = "arn:aws:kms:us-east-2:ACCOUNT_ID:key/KEY_ID"
    
    # Enable state file versioning for backup/recovery
    versioning = true
  }
}

# Note: The S3 bucket and DynamoDB table will be created automatically
# by the GitHub Actions workflow before Terraform initialization
