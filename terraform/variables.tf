# Terraform variables for AWS EC2 user provisioning

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-west-2"
}

variable "instance_ids" {
  description = "List of EC2 instance IDs where users should be provisioned"
  type        = list(string)
}

variable "ssh_private_key_path" {
  description = "Path to the private SSH key for connecting to EC2 instances"
  type        = string
  default     = "~/.ssh/ec2-provisioning-key"
}

variable "ssh_user" {
  description = "SSH user for connecting to EC2 instances (usually 'ec2-user' for Amazon Linux 2)"
  type        = string
  default     = "ec2-user"
}

variable "users_file" {
  description = "Path to the YAML file containing user information"
  type        = string
  default     = "../users.yaml"
}

variable "dry_run" {
  description = "Enable dry-run mode to test without making changes"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "ec2-user-provisioning"
    Environment = "production"
    ManagedBy   = "terraform"
  }
} 