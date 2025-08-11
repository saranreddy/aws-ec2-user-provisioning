# Main Terraform configuration for AWS EC2 user provisioning
# This file handles the creation of users and SSH keys on EC2 instances

provider "aws" {
  region = var.aws_region
}

# Data source to read user configuration from YAML file
data "local_file" "users_config" {
  filename = var.users_file
}

# S3-based SSH Key Management
# Keys are pre-generated and stored in S3 bucket, then retrieved as needed

# S3 bucket for storing SSH keys
# Use the bucket created by the workflow, or create a new one if it doesn't exist
resource "aws_s3_bucket" "ssh_keys" {
  bucket = var.ssh_keys_bucket_name

  tags = var.tags
}

# Enable versioning for key history
resource "aws_s3_bucket_versioning" "ssh_keys_versioning" {
  bucket = aws_s3_bucket.ssh_keys.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "ssh_keys_encryption" {
  bucket = aws_s3_bucket.ssh_keys.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Block public access to the keys bucket
resource "aws_s3_bucket_public_access_block" "ssh_keys_pab" {
  bucket = aws_s3_bucket.ssh_keys.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Fetch public keys from S3 for each user
# Note: This will only work after keys are uploaded to S3
# During validation, this data source may not be accessible
data "aws_s3_object" "user_public_keys" {
  for_each = { for user in yamldecode(data.local_file.users_config.content).users : user.username => user }

  bucket = aws_s3_bucket.ssh_keys.bucket
  key    = "keys/${each.key}_public_key"

  depends_on = [aws_s3_bucket.ssh_keys]
}

# Verify all required keys exist in S3 before proceeding
# This resource only runs during apply, not during validation
resource "null_resource" "verify_keys_exist" {
  for_each = var.dry_run ? {} : { for user in yamldecode(data.local_file.users_config.content).users : user.username => user }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Checking if keys exist for user: ${each.key}"
      aws s3 ls s3://${aws_s3_bucket.ssh_keys.bucket}/keys/${each.key}_public_key || {
        echo "ERROR: Public key for user ${each.key} not found in S3"
        echo "Expected location: s3://${aws_s3_bucket.ssh_keys.bucket}/keys/${each.key}_public_key"
        echo "Please ensure keys are generated and uploaded before running Terraform"
        exit 1
      }
      aws s3 ls s3://${aws_s3_bucket.ssh_keys.bucket}/keys/${each.key}_private_key || {
        echo "ERROR: Private key for user ${each.key} not found in S3"
        echo "Expected location: s3://${aws_s3_bucket.ssh_keys.bucket}/keys/${each.key}_private_key"
        echo "Please ensure keys are generated and uploaded before running Terraform"
        exit 1
      }
      echo "✅ Keys verified for user: ${each.key}"
    EOT
  }

  triggers = {
    users_hash = md5(data.local_file.users_config.content)
    bucket_id  = aws_s3_bucket.ssh_keys.id
  }
}

# Provision users on each EC2 instance
resource "null_resource" "provision_users" {
  for_each = { for instance_id in var.instance_ids : instance_id => instance_id }

  triggers = {
    # Trigger when user list changes or when S3 keys change
    users_hash   = md5(data.local_file.users_config.content)
    s3_keys_hash = try(md5(join("", [for key in data.aws_s3_object.user_public_keys : key.body])), "no-keys-yet")
    instance_id  = each.value
  }

  # Validate that instance has public IP and is running
  lifecycle {
    precondition {
      condition     = data.aws_instance.instance[each.key].public_ip != null
      error_message = "Instance ${each.value} does not have a public IP address. Please ensure the instance has a public IP or use a bastion host."
    }
    precondition {
      condition     = data.aws_instance.instance[each.key].instance_state == "running"
      error_message = "Instance ${each.value} is not running. Current state: ${data.aws_instance.instance[each.key].instance_state}"
    }
  }

  connection {
    type        = "ssh"
    host        = data.aws_instance.instance[each.key].private_ip
    user        = var.ssh_user
    private_key = file(var.ssh_private_key_path)
    timeout     = "5m"
    agent       = false
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Starting user provisioning on instance ${each.value}'",
      "sudo yum update -y || true",
      "sudo yum install -y openssh-clients || true"
    ]
  }

  # Create users and add SSH keys from S3
  provisioner "remote-exec" {
    inline = concat(
      ["echo 'Creating users and setting up SSH keys from S3...'"],
      ["echo 'Skipping YUM updates to avoid proxy timeout...'"],
      flatten([
        for user in yamldecode(data.local_file.users_config.content).users : [
          "echo 'Processing user: ${user.username}'",

          # Create user account
          "sudo useradd -m -s /bin/bash -c '${user.full_name}' ${user.username} || echo 'User ${user.username} already exists'",

          # Create .ssh directory with proper permissions
          "sudo mkdir -p /home/${user.username}/.ssh",
          "sudo chown ${user.username}:${user.username} /home/${user.username}/.ssh",
          "sudo chmod 700 /home/${user.username}/.ssh",

          # Install public key from S3 to authorized_keys
          "echo '${try(data.aws_s3_object.user_public_keys[user.username].body, "# Key not available during validation")}' | sudo tee /home/${user.username}/.ssh/authorized_keys",
          "sudo chown ${user.username}:${user.username} /home/${user.username}/.ssh/authorized_keys",
          "sudo chmod 600 /home/${user.username}/.ssh/authorized_keys",

          # Validate the key format
          "if sudo ssh-keygen -l -f /home/${user.username}/.ssh/authorized_keys >/dev/null 2>&1; then",
          "  echo '✅ Valid SSH key installed for ${user.username}'",
          "else",
          "  echo '❌ WARNING: Invalid SSH key format for ${user.username}'",
          "fi",

          # Test key permissions
          "sudo -u ${user.username} test -r /home/${user.username}/.ssh/authorized_keys && echo '✅ Key file readable by ${user.username}' || echo '❌ Key file not readable by ${user.username}'",

          "echo 'User ${user.username} provisioned successfully with S3-stored key'"
        ]
      ]),
      ["echo 'User provisioning completed on instance ${each.value} using S3-stored keys'"]
    )
  }
}

# Data source to get instance information
data "aws_instance" "instance" {
  for_each    = { for instance_id in var.instance_ids : instance_id => instance_id }
  instance_id = each.value
}

# Validate SSH private key file exists (commented out for debugging)
# data "local_file" "ssh_private_key" {
#   filename = var.ssh_private_key_path
# 
#   lifecycle {
#     precondition {
#       condition     = fileexists(var.ssh_private_key_path)
#       error_message = "SSH private key file '${var.ssh_private_key_path}' does not exist. Please ensure the file exists and has correct permissions."
#     }
#   }
# }



# Output instance information
output "provisioned_instances" {
  description = "Information about instances where users were provisioned"
  value = {
    for instance_id, instance in data.aws_instance.instance : instance_id => {
      instance_id   = instance.instance_id
      public_ip     = instance.public_ip
      private_ip    = instance.private_ip
      instance_type = instance.instance_type
      state         = instance.instance_state
    }
  }
}

# Output summary
output "provisioning_summary" {
  description = "Summary of user provisioning"
  value = {
    total_users     = length(yamldecode(data.local_file.users_config.content).users)
    total_instances = length(var.instance_ids)
    users = [for user in yamldecode(data.local_file.users_config.content).users : {
      username  = user.username
      email     = user.email
      full_name = user.full_name
    }]
    instances = var.instance_ids
  }
} 