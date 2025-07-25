# Main Terraform configuration for AWS EC2 user provisioning
# This file handles the creation of users and SSH keys on EC2 instances

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data source to read user configuration from YAML file
data "local_file" "users_config" {
  filename = var.users_file
}

# Parse YAML content
locals {
  users = yamldecode(data.local_file.users_config.content).users
}

# Generate SSH key pairs for each user
resource "tls_private_key" "user_keys" {
  for_each = { for user in local.users : user.username => user }
  
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Store private keys locally (these will be emailed to users)
resource "local_file" "private_keys" {
  for_each = { for user in local.users : user.username => user }
  
  filename = "${path.module}/keys/${each.key}_private_key.pem"
  content  = tls_private_key.user_keys[each.key].private_key_pem
  
  file_permission = "0600"
}

# Store public keys locally
resource "local_file" "public_keys" {
  for_each = { for user in local.users : user.username => user }
  
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
    users_hash = md5(data.local_file.users_config.content)
    keys_hash  = md5(join("", [for key in tls_private_key.user_keys : key.private_key_pem]))
    instance_id = each.value
  }
  
  connection {
    type        = "ssh"
    host        = data.aws_instance.instance[each.key].public_ip
    user        = var.ssh_user
    private_key = file(var.ssh_private_key_path)
    timeout     = "5m"
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
        for user in local.users : [
          "echo 'Processing user: ${user.username}'",
          "sudo useradd -m -s /bin/bash -c '${user.full_name}' ${user.username} || echo 'User ${user.username} already exists'",
          "sudo mkdir -p /home/${user.username}/.ssh",
          "sudo chown ${user.username}:${user.username} /home/${user.username}/.ssh",
          "sudo chmod 700 /home/${user.username}/.ssh",
          "echo '${tls_private_key.user_keys[user.username].public_key_openssh}' | sudo tee -a /home/${user.username}/.ssh/authorized_keys",
          "sudo chown ${user.username}:${user.username} /home/${user.username}/.ssh/authorized_keys",
          "sudo chmod 600 /home/${user.username}/.ssh/authorized_keys",
          "echo 'User ${user.username} provisioned successfully'"
        ]
      ]),
      ["echo 'User provisioning completed on instance ${each.value}'"]
    )
  }
}

# Data source to get instance information
data "aws_instance" "instance" {
  for_each = { for instance_id in var.instance_ids : instance_id => instance_id }
  instance_id = each.value
}

# Output the generated keys for emailing
output "user_private_keys" {
  description = "Private SSH keys for each user (to be emailed)"
  value = {
    for username, user in local.users : username => {
      private_key = tls_private_key.user_keys[username].private_key_pem
      public_key  = tls_private_key.user_keys[username].public_key_openssh
      email       = user.email
      full_name   = user.full_name
    }
  }
  sensitive = true
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
    total_users    = length(local.users)
    total_instances = length(var.instance_ids)
    users = [for user in local.users : {
      username = user.username
      email    = user.email
      full_name = user.full_name
    }]
    instances = var.instance_ids
  }
} 