# Main Terraform configuration for AWS EC2 user provisioning
# This file handles the creation of users and SSH keys on EC2 instances

provider "aws" {
  region = var.aws_region
}

# Data source to read user configuration from YAML file
data "local_file" "users_config" {
  filename = var.users_file
}

# Data source to get instance information
data "aws_instance" "instance" {
  for_each    = { for instance_id in var.instance_ids : instance_id => instance_id }
  instance_id = each.value
}

# Provision users on each EC2 instance
resource "null_resource" "provision_users" {
  for_each = { for instance_id in var.instance_ids : instance_id => instance_id }

  triggers = {
    # Trigger when user list changes or when SSH keys change
    users_hash   = md5(data.local_file.users_config.content)
    s3_keys_hash = try(md5(join("", [for key in var.user_public_keys : key])), "no-keys-yet")
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
    host        = data.aws_instance.instance[each.key].public_ip
    user        = var.ssh_user
    private_key = file(var.ssh_private_key_path)
    timeout     = "5m"
    agent       = false
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Starting user provisioning on instance ${each.value}'",
      "sudo yum update -y || true",
      "sudo yum install -y openssh-clients awscli || true",
      "echo 'Configuring AWS credentials for S3 access...'",
      "mkdir -p ~/.aws",
      "echo '[default]' > ~/.aws/config",
      "echo 'region = ${var.aws_region}' >> ~/.aws/config"
    ]
  }

  # Create users and add SSH keys from variables
  provisioner "remote-exec" {
    inline = concat(
      ["echo 'Creating users and setting up SSH keys...'"],
      flatten([
        for user in yamldecode(data.local_file.users_config.content).users : [
          "echo 'Processing user: ${user.username}'",

          # Check if user already exists and create if needed
          "if ! id '${user.username}' >/dev/null 2>&1; then",
          "  echo 'Creating new user account for ${user.username}...'",
          "  sudo useradd -m -s /bin/bash -c '${user.full_name}' ${user.username}",
          "  echo '✅ User ${user.username} created successfully'",
          "else",
          "  echo 'User ${user.username} already exists, updating account...'",
          "  sudo usermod -c '${user.full_name}' ${user.username}",
          "  echo '✅ User ${user.username} account updated'",
          "fi",

          # Create .ssh directory with proper permissions
          "sudo mkdir -p /home/${user.username}/.ssh",
          "sudo chown ${user.username}:${user.username} /home/${user.username}/.ssh",
          "sudo chmod 700 /home/${user.username}/.ssh",

          # Install public key directly from variable
          "echo 'Installing SSH key for ${user.username}...'",
          "if [ -n '${var.user_public_keys[user.username]}' ]; then",
          "  echo '${var.user_public_keys[user.username]}' | sudo tee /home/${user.username}/.ssh/authorized_keys",
          "  echo '✅ SSH key installed for ${user.username}'",
          "else",
          "  echo '⚠️  No SSH key available for ${user.username}, skipping key installation'",
          "  echo '# SSH key not available during this run' | sudo tee /home/${user.username}/.ssh/authorized_keys",
          "fi",
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

          "echo 'User ${user.username} provisioned successfully'"
        ]
      ]),
      ["echo 'User provisioning completed on instance ${each.value}'"]
    )
  }
}

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