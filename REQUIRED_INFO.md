# Required Information Checklist

## 🔑 AWS Information

### AWS Credentials
- [ ] **AWS Access Key ID**: `AKIA...` (20 characters)
- [ ] **AWS Secret Access Key**: `...` (40 characters)
- [ ] **AWS Region**: `us-west-2` (or your preferred region)

### EC2 Instances
- [ ] **EC2 Instance IDs**: List of instance IDs where users should be provisioned
  - Example: `["i-1234567890abcdef0", "i-0987654321fedcba0"]`
  - Find in: AWS Console → EC2 → Instances → Copy Instance ID

### SSH Access
- [ ] **SSH Private Key Path**: Path to key used to launch EC2 instances
  - Default: `~/.ssh/ec2-provisioning-key`
  - Must have permissions to connect to your EC2 instances

## 📧 SMTP Email Information

### SMTP Server Details
- [ ] **SMTP Host**: Email server hostname
  - Gmail: `smtp.gmail.com`
  - SendGrid: `smtp.sendgrid.net`
  - AWS SES: `email-smtp.us-west-2.amazonaws.com`
  - Office 365: `smtp.office365.com`

- [ ] **SMTP Port**: Usually `587` (TLS) or `465` (SSL)
- [ ] **SMTP Username**: Your email address or SMTP username
- [ ] **SMTP Password**: Your email password or app password

### Email Provider Setup

#### Gmail Setup
- [ ] Enable 2-Factor Authentication on Gmail account
- [ ] Generate App Password:
  1. Go to Google Account settings
  2. Security → 2-Step Verification → App passwords
  3. Generate password for "Mail"
- [ ] Use App Password (not regular password) as SMTP password

#### SendGrid Setup
- [ ] Create SendGrid account
- [ ] Generate API Key
- [ ] Use API Key as SMTP password
- [ ] Use `apikey` as SMTP username

#### AWS SES Setup
- [ ] Verify sender email address in AWS SES
- [ ] Use IAM credentials for SMTP
- [ ] Ensure SES is out of sandbox mode (if needed)

## 👥 User Information

### User List (users.yaml)
- [ ] **Usernames**: Linux usernames for each user
- [ ] **Email Addresses**: Valid email addresses for each user
- [ ] **Full Names**: Display names for each user

Example:
```yaml
users:
  - username: alice
    email: alice@yourcompany.com
    full_name: "Alice Johnson"
    
  - username: bob
    email: bob@yourcompany.com
    full_name: "Bob Smith"
```

## 🔧 GitHub Secrets (for GitHub Actions)

### Required Secrets
- [ ] `AWS_ACCESS_KEY_ID`: Your AWS access key
- [ ] `AWS_SECRET_ACCESS_KEY`: Your AWS secret key
- [ ] `SMTP_HOST`: Your SMTP server hostname
- [ ] `SMTP_USER`: Your SMTP username
- [ ] `SMTP_PASS`: Your SMTP password
- [ ] `SMTP_PORT`: Your SMTP port (optional, defaults to 587)

## 🧪 Testing Information

### Test Instance
- [ ] **Test EC2 Instance ID**: One instance for testing
- [ ] **Test User**: One user for initial testing
- [ ] **Test Email**: Email address for testing

### Dry Run Mode
- [ ] Test with `dry_run = true` first
- [ ] Verify Terraform plan output
- [ ] Test email script with `--dry-run` flag

## 📝 Configuration Files

### Terraform Variables
- [ ] Create `terraform/terraform.tfvars` from example
- [ ] Set `instance_ids` with your actual instance IDs
- [ ] Configure `aws_region` if different from default
- [ ] Set `ssh_private_key_path` if different from default

### User Configuration
- [ ] Update `users.yaml` with your actual users
- [ ] Verify email addresses are correct
- [ ] Ensure usernames follow Linux naming conventions

## 🔒 Security Considerations

### SSH Key Security
- [ ] SSH private key has 600 permissions
- [ ] SSH key is not committed to version control
- [ ] SSH key has access to target EC2 instances

### Email Security
- [ ] Use TLS/SSL for SMTP connections
- [ ] Store SMTP credentials securely
- [ ] Use app passwords for Gmail (not regular passwords)

### AWS Security
- [ ] IAM user has minimal required permissions
- [ ] Access keys are rotated regularly
- [ ] CloudTrail is enabled for audit logging

## 🚀 Pre-flight Checklist

Before running the project:

- [ ] All AWS credentials are valid and have proper permissions
- [ ] EC2 instances are running and accessible
- [ ] SSH key can connect to EC2 instances
- [ ] SMTP credentials are working (test with email client)
- [ ] User list is complete and accurate
- [ ] GitHub secrets are configured (if using GitHub Actions)
- [ ] Terraform is installed and configured
- [ ] Python dependencies are installed
- [ ] Dry run test passes successfully

## 📞 Troubleshooting Information

### Common Issues
- [ ] SSH connection timeout: Check security groups, instance state
- [ ] SMTP authentication failed: Verify credentials, 2FA setup
- [ ] User already exists: Normal behavior, script is idempotent
- [ ] Terraform state issues: Check AWS permissions, region

### Debug Commands
```bash
# Test SSH connectivity
ssh -i ~/.ssh/your-key.pem -o ConnectTimeout=10 ec2-user@instance-ip

# Test SMTP connection
telnet smtp.gmail.com 587

# Check AWS credentials
aws sts get-caller-identity

# Validate Terraform
terraform validate
``` 