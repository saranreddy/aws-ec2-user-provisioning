# Terraform outputs for AWS EC2 user provisioning

output "provisioning_complete" {
  description = "Confirmation that user provisioning has completed"
  value       = "User provisioning completed successfully!"
}

output "users_created" {
  description = "List of users that were created"
  value = {
    for username, user in yamldecode(data.local_file.users_config.content).users : username => {
      username  = user.username
      email     = user.email
      full_name = user.full_name
    }
  }
}

output "instances_provisioned" {
  description = "List of instances where users were provisioned"
  value       = var.instance_ids
}

output "user_s3_key_locations" {
  description = "S3 locations of SSH keys for each user (to be downloaded for emailing)"
  value = {
    for username, user in yamldecode(data.local_file.users_config.content).users : username => {
      private_key_s3_path = "s3://${data.aws_s3_bucket.ssh_keys.bucket}/keys/${username}_private_key"
      public_key_s3_path  = "s3://${data.aws_s3_bucket.ssh_keys.bucket}/keys/${username}_public_key"
      email               = user.email
      full_name           = user.full_name
    }
  }
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket storing SSH keys"
  value       = data.aws_s3_bucket.ssh_keys.bucket
}

output "next_steps" {
  description = "Next steps after provisioning"
  value = [
    "1. SSH keys have been generated and stored securely in S3 bucket: ${data.aws_s3_bucket.ssh_keys.bucket}",
    "2. Users have been created on all specified EC2 instances",
    "3. Public keys from S3 have been added to each user's authorized_keys",
    "4. Private keys will be downloaded from S3 and emailed to users automatically",
    "5. Users can SSH to instances using their private keys downloaded from email"
  ]
} 