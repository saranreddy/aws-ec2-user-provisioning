# Main Terraform configuration for AWS EC2 user provisioning
# This file now focuses on infrastructure validation and basic setup
# User provisioning is handled directly by the GitHub Actions workflow

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

# Validate EC2 instances are accessible and ready for user provisioning
resource "null_resource" "validate_instances" {
  for_each = { for instance_id in var.instance_ids : instance_id => instance_id }

  triggers = {
    # Trigger when user list changes or when instance changes
    users_hash   = md5(data.local_file.users_config.content)
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

  # Basic connectivity test and instance readiness check
  provisioner "remote-exec" {
    inline = [
      "echo 'Validating instance ${each.value} is ready for user provisioning...'",
      "echo 'Instance ID: ${each.value}'",
      "echo 'Public IP: ${data.aws_instance.instance[each.key].public_ip}'",
      "echo 'Instance State: ${data.aws_instance.instance[each.key].instance_state}'",
      "echo 'Instance Type: ${data.aws_instance.instance[each.key].instance_type}'",
      "echo '✅ Instance ${each.value} is ready for user provisioning'"
    ]
  }
}

 