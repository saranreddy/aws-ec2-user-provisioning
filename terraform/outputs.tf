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

output "ssh_key_status" {
  description = "Status of SSH key installation for each user"
  value = {
    for username, user in yamldecode(data.local_file.users_config.content).users : username => {
      username     = user.username
      email        = user.email
      full_name    = user.full_name
      ssh_key_installed = contains(keys(var.user_public_keys), username)
    }
  }
}

output "next_steps" {
  description = "Next steps after provisioning"
  value = [
    "1. SSH keys have been generated and installed on EC2 instances",
    "2. Users have been created on all specified EC2 instances",
    "3. Public keys have been added to each user's authorized_keys",
    "4. Users can SSH to instances using their private keys",
    "5. SSH keys are available in the workflow for distribution"
  ]
} 