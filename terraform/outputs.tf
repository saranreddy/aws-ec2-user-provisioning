# Terraform outputs for AWS EC2 user provisioning
# This file now outputs information for the workflow to use

output "provisioning_ready" {
  description = "Confirmation that instances are ready for user provisioning"
  value       = "Instances validated and ready for user provisioning by workflow!"
}

output "instance_details" {
  description = "Details of instances ready for user provisioning"
  value = {
    for instance_id in var.instance_ids : instance_id => {
      instance_id   = instance_id
      public_ip     = data.aws_instance.instance[instance_id].public_ip
      private_ip    = data.aws_instance.instance[instance_id].private_ip
      instance_type = data.aws_instance.instance[instance_id].instance_type
      state         = data.aws_instance.instance[instance_id].instance_state
      region        = var.aws_region
    }
  }
}

output "user_configuration" {
  description = "User configuration loaded from YAML file"
  value = yamldecode(data.local_file.users_config.content)
}

output "workflow_next_steps" {
  description = "Next steps for the workflow after Terraform validation"
  value = [
    "1. Terraform validation completed successfully",
    "2. EC2 instances are accessible and ready",
    "3. Workflow will now create users and install SSH keys directly",
    "4. SSH keys will be uploaded to S3 for user distribution",
    "5. Users will be able to SSH to instances using their private keys"
  ]
} 