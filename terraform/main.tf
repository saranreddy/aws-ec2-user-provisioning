# Main Terraform configuration for AWS EC2 user provisioning
# This file handles the creation of users and SSH keys on EC2 instances

provider "aws" {
  region = var.aws_region
}

# Data source to read user configuration from YAML file
data "local_file" "users_config" {
  filename = var.users_file
}

# Generate SSH key pairs for each user
resource "tls_private_key" "user_keys" {
  for_each = { for user in yamldecode(data.local_file.users_config.content).users : user.username => user }

  algorithm = "RSA"
  rsa_bits  = 4096

  lifecycle {
    create_before_destroy = true
  }
}

# Store private keys locally (these will be emailed to users)
resource "local_file" "private_keys" {
  for_each = { for user in yamldecode(data.local_file.users_config.content).users : user.username => user }

  filename = "${path.module}/keys/${each.key}_private_key.pem"
  content  = tls_private_key.user_keys[each.key].private_key_pem

  file_permission = "0600"
}

# Store public keys locally
resource "local_file" "public_keys" {
  for_each = { for user in yamldecode(data.local_file.users_config.content).users : user.username => user }

  filename = "${path.module}/keys/${each.key}_public_key.pub"
  content  = tls_private_key.user_keys[each.key].public_key_openssh

  file_permission = "0644"
}

# Create directory for keys
resource "local_file" "keys_directory" {
  filename = "${path.module}/keys/.gitkeep"
  content  = ""

  file_permission = "0644"
}

# Provision users on each EC2 instance
resource "null_resource" "provision_users" {
  for_each = { for instance_id in var.instance_ids : instance_id => instance_id }

  triggers = {
    # Trigger when user list changes or when keys are regenerated
    users_hash  = md5(data.local_file.users_config.content)
    keys_hash   = md5(join("", [for key in tls_private_key.user_keys : key.private_key_pem]))
    instance_id = each.value
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

  # Create users and add SSH keys
  provisioner "remote-exec" {
    inline = concat(
      ["echo 'Creating users and setting up SSH keys...'"],
      flatten([
        for user in yamldecode(data.local_file.users_config.content).users : [
          "echo 'Processing user: ${user.username}'",
          "sudo useradd -m -s /bin/bash -c '${user.full_name}' ${user.username} || echo 'User ${user.username} already exists'",
          "sudo mkdir -p /home/${user.username}/.ssh",
          "sudo chown ${user.username}:${user.username} /home/${user.username}/.ssh",
          "sudo chmod 700 /home/${user.username}/.ssh",
          "echo '${tls_private_key.user_keys[user.username].private_key_pem}' | sudo tee /home/${user.username}/.ssh/${user.username}_key",
          "echo '${tls_private_key.user_keys[user.username].public_key_openssh}' | sudo tee /home/${user.username}/.ssh/${user.username}_key.pub",
          "echo '${tls_private_key.user_keys[user.username].public_key_openssh}' | sudo tee -a /home/${user.username}/.ssh/authorized_keys",
          "sudo chown ${user.username}:${user.username} /home/${user.username}/.ssh/${user.username}_key",
          "sudo chown ${user.username}:${user.username} /home/${user.username}/.ssh/${user.username}_key.pub",
          "sudo chown ${user.username}:${user.username} /home/${user.username}/.ssh/authorized_keys",
          "sudo chmod 600 /home/${user.username}/.ssh/${user.username}_key",
          "sudo chmod 644 /home/${user.username}/.ssh/${user.username}_key.pub",
          "sudo chmod 600 /home/${user.username}/.ssh/authorized_keys",
          "echo 'User ${user.username} provisioned successfully with keys in /home/${user.username}/.ssh/'"
        ]
      ]),
      ["echo 'User provisioning completed on instance ${each.value}'"]
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