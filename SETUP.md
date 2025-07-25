# Setup Guide - AWS EC2 User Provisioning

This guide will walk you through setting up and running the AWS EC2 User Provisioning project.

## 🚀 Quick Start

### Prerequisites Checklist

Before you begin, ensure you have:

- [ ] **AWS Account** with EC2 instances running
- [ ] **GitHub Account** (for GitHub Actions)
- [ ] **SMTP Server** (Gmail, SendGrid, etc.)
- [ ] **SSH Key** to access your EC2 instances

### Step 1: Clone the Repository

```bash
git clone <your-repo-url>
cd aws-ec2-user-provisioning
```

### Step 2: Configure Users

Edit `users.yaml` with your user information:

```yaml
users:
  - username: alice
    email: alice@yourcompany.com
    full_name: "Alice Johnson"
    
  - username: bob
    email: bob@yourcompany.com
    full_name: "Bob Smith"
```

### Step 3: Configure GitHub Secrets

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Add the following secrets:

#### AWS Credentials
- `AWS_ACCESS_KEY_ID`: Your AWS access key
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret key

#### SMTP Credentials
- `SMTP_HOST`: SMTP server (e.g., `smtp.gmail.com`)
- `SMTP_USER`: SMTP username (e.g., `admin@yourcompany.com`)
- `SMTP_PASS`: SMTP password or app password
- `SMTP_PORT`: SMTP port (optional, defaults to `587`)

### Step 4: Run the Workflow

1. Go to **Actions** tab in your GitHub repository
2. Select **"Provision Users on AWS EC2 Instances"**
3. Click **"Run workflow"**
4. Enter your EC2 instance IDs (comma-separated)
5. Choose options:
   - **Dry run**: Test without making changes
   - **Send emails**: Automatically email SSH keys to users

## 🔧 Local Development Setup

### Install Dependencies

```bash
# Install Terraform
brew install terraform  # macOS
# or download from https://terraform.io

# Install Python dependencies
pip3 install -r scripts/requirements.txt

# Install AWS CLI (optional)
brew install awscli  # macOS
```

### Configure AWS

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter your default region (e.g., us-west-2)
```

### Configure Terraform Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your instance IDs:

```hcl
instance_ids = [
  "i-1234567890abcdef0",
  "i-0987654321fedcba0"
]
```

### Run Locally

```bash
# Initialize Terraform
cd terraform
terraform init

# Plan the changes
terraform plan

# Apply the changes
terraform apply

# Send emails (optional)
cd ..
python3 scripts/send_keys.py \
  --smtp-host "smtp.gmail.com" \
  --smtp-user "admin@yourcompany.com" \
  --smtp-pass "your-app-password" \
  --users-file users.yaml \
  --terraform-dir terraform
```

## 📧 Email Configuration

### Gmail Setup

1. Enable 2-factor authentication on your Gmail account
2. Generate an App Password:
   - Go to Google Account settings
   - Security → 2-Step Verification → App passwords
   - Generate password for "Mail"
3. Use the app password in your SMTP configuration

### Other SMTP Providers

| Provider | SMTP Host | Port | Notes |
|----------|-----------|------|-------|
| Gmail | smtp.gmail.com | 587 | Requires app password |
| SendGrid | smtp.sendgrid.net | 587 | API key as password |
| AWS SES | email-smtp.us-west-2.amazonaws.com | 587 | IAM credentials |
| Office 365 | smtp.office365.com | 587 | Modern authentication |

## 🔒 Security Best Practices

### SSH Key Management

- Store SSH keys securely (never commit to git)
- Use proper file permissions (600 for private keys)
- Rotate keys regularly
- Use passphrases for additional security

### AWS Security

- Use IAM roles with minimal required permissions
- Enable CloudTrail for audit logging
- Use VPC security groups to restrict SSH access
- Consider using AWS Systems Manager Session Manager

### Email Security

- Use TLS/SSL for SMTP connections
- Store SMTP credentials securely
- Validate email addresses before sending
- Monitor email delivery logs

## 🧪 Testing

### Dry Run Mode

Test the workflow without making changes:

```bash
# GitHub Actions
# Enable "dry run" option when running workflow

# Local Terraform
terraform plan -var="dry_run=true"

# Email script
python3 scripts/send_keys.py --dry-run
```

### Validation Steps

1. **Check User Creation**:
   ```bash
   ssh -i ~/.ssh/your-key.pem ec2-user@your-instance-ip
   sudo cat /etc/passwd | grep alice
   ```

2. **Test SSH Access**:
   ```bash
   ssh -i terraform/keys/alice_private_key.pem alice@your-instance-ip
   ```

3. **Verify Email Delivery**:
   - Check user email inbox
   - Review SMTP server logs
   - Check GitHub Actions logs

## 🚨 Troubleshooting

### Common Issues

#### SSH Connection Failed
```
Error: timeout waiting for SSH connection
```

**Solutions**:
- Verify EC2 instance is running
- Check security group allows SSH (port 22)
- Verify SSH key path and permissions
- Ensure instance has public IP

#### Email Delivery Failed
```
Error: SMTP authentication failed
```

**Solutions**:
- Verify SMTP credentials
- Check if 2FA is enabled (Gmail)
- Use app password instead of regular password
- Test SMTP connection manually

#### User Already Exists
```
Error: useradd: user 'alice' already exists
```

**Solutions**:
- This is normal - the script is idempotent
- Existing users won't be duplicated
- Check if user was created successfully

### Debug Commands

```bash
# Check Terraform state
terraform show

# Check SSH connectivity
ssh -i ~/.ssh/your-key.pem -o ConnectTimeout=10 ec2-user@instance-ip

# Test SMTP connection
telnet smtp.gmail.com 587

# Check user creation on instance
ssh -i ~/.ssh/your-key.pem ec2-user@instance-ip "sudo id alice"
```

## 📊 Monitoring

### GitHub Actions Logs

- Check workflow run logs for detailed output
- Review each job's logs for specific errors
- Monitor execution time and resource usage

### AWS CloudWatch

- Monitor EC2 instance metrics
- Set up alarms for SSH connection failures
- Track user login attempts

### Email Monitoring

- Check SMTP server delivery logs
- Monitor bounce rates and delivery failures
- Set up email delivery notifications

## 🔄 Maintenance

### Regular Tasks

1. **Update User List**: Modify `users.yaml` as needed
2. **Rotate SSH Keys**: Generate new keys periodically
3. **Review Access**: Audit user access regularly
4. **Update Dependencies**: Keep Terraform and Python packages updated

### Backup and Recovery

1. **Backup SSH Keys**: Store keys securely off-site
2. **Document Configuration**: Keep configuration files versioned
3. **Test Recovery**: Regularly test the provisioning process

## 📞 Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review GitHub Actions logs
3. Test components individually
4. Open an issue with detailed error information

Include in your issue:
- Error messages and logs
- Configuration details (without sensitive data)
- Steps to reproduce the issue
- Environment information 