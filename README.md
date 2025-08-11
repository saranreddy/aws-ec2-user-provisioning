# AWS EC2 User Provisioning with Terraform and GitHub Actions

This project automates user provisioning on AWS EC2 instances using Terraform and GitHub Actions. It creates unique Linux user accounts and SSH key pairs for each user, then emails the private keys to users.

## 🚀 Features

- ✅ **Automated User Provisioning**: Creates Linux user accounts on EC2 instances
- ✅ **Unique SSH Key Pairs**: Generates individual SSH keys for each user
- ✅ **Cross-Instance Access**: Same username/key works across all EC2 instances
- ✅ **Email Delivery**: Automatically emails SSH private keys to users
- ✅ **GitHub Actions Integration**: Fully automated CI/CD pipeline
- ✅ **Dry Run Mode**: Test provisioning without making changes
- ✅ **Idempotent Operations**: Safe to re-run without duplicating users
- ✅ **Amazon Linux 2 Support**: Optimized for Amazon Linux 2 EC2 instances
- ✅ **Enterprise-Grade Security**: OIDC-based authentication, input validation, timeout management

## 📁 Project Structure

```
aws-ec2-user-provisioning/
├── .github/
│   └── workflows/
│       └── provision-users.yml    # GitHub Actions workflow
├── terraform/
│   ├── main.tf                    # Main Terraform configuration
│   ├── variables.tf               # Input variables
│   ├── versions.tf                # Provider versions
│   └── keys/                      # Generated SSH keys (gitignored)
├── scripts/
│   ├── send_keys.py               # Email script for SSH keys
│   ├── test_workflow.sh           # Comprehensive validation script
│   └── quick_test.sh              # Quick validation script
├── users.yaml                     # User configuration file
├── README.md                      # This file
└── .gitignore                     # Git ignore rules
```

## 🛠️ Prerequisites

### Required Software
- **Terraform** >= 1.0
- **Python** >= 3.6
- **Git** (for version control)
- **AWS CLI** (for local testing)

### Required AWS Resources
- **EC2 Instances**: Running Amazon Linux 2 instances with public IPs
- **SSH Access**: Private key to connect to EC2 instances
- **IAM Permissions**: Read access to EC2 instances
- **OIDC Role**: Configured for GitHub Actions (see AWS OIDC Configuration below)

## 🔧 AWS OIDC Configuration

### Required GitHub Secrets
```bash
# AWS OIDC Configuration
aws_ec2_creation_role=cat-infra-oidc-githubactions

# SMTP Configuration (for email functionality)
SMTP_HOST=your-smtp-server.com
SMTP_USER=your-smtp-username
SMTP_PASS=your-smtp-password
SMTP_PORT=587  # Optional, defaults to 587
```

### Optional GitHub Variables
```bash
# Session duration for AWS credentials (optional)
GITHUBACTIONSAPPSESSION=3600  # Defaults to 3600 seconds
```

### AWS OIDC Role Setup

1. **Create OIDC Role in AWS**:
   ```bash
   # Role ARN format
   arn:aws:iam::YOUR_ACCOUNT_ID:role/cat-infra-oidc-githubactions
   ```

2. **Trust Policy**:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
         },
         "Action": "sts:AssumeRoleWithWebIdentity",
         "Condition": {
           "StringEquals": {
             "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
           },
           "StringLike": {
             "token.actions.githubusercontent.com:sub": "repo:YOUR_ORG/YOUR_REPO:*"
           }
         }
       }
     ]
   }
   ```

3. **Permissions Policy**:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "ec2:DescribeInstances",
           "ec2:DescribeInstanceStatus"
         ],
         "Resource": "*"
       }
     ]
   }
   ```

## 📋 Configuration

### 1. User Configuration (`users.yaml`)

Define users in the `users.yaml` file:

```yaml
users:
  - username: rai002
    email: raghavee.ai@umb.com
    full_name: "Raghavee A"
    
  - username: hhe004
    email: harsha-venkatraman.hegde@umb.com
    full_name: "Hasha Venkararaman"
```

### 2. Workflow Inputs

When manually triggering the workflow, you can specify:

- `instance_ids`: Comma-separated list of EC2 instance IDs (required)
- `aws_account_id`: AWS Account ID (required, defaults to `872515261591`)
- `aws_region`: AWS Region (required, choice between `us-east-2`, `us-west-2`, `us-east-1`)
- `dry_run`: Enable dry run mode (optional, defaults to false)
- `send_emails`: Send SSH keys to users via email (optional, defaults to true)

## 🚀 Usage

### Method 1: GitHub Actions (Recommended)

1. **Fork/Clone** this repository
2. **Configure Secrets** in GitHub repository settings:
   - Go to Settings → Secrets and variables → Actions
   - Add all required secrets (see AWS OIDC Configuration above)
3. **Update Users**: Modify `users.yaml` with your user list
4. **Run Workflow**:
   - Go to Actions tab
   - Select "Provision Users on AWS EC2 Instances"
   - Click "Run workflow"
   - Enter instance IDs (comma-separated)
   - Choose options (dry run, email sending, etc.)

### Method 2: Local Terraform

1. **Install Dependencies**:
   ```bash
   # Install Terraform
   brew install terraform  # macOS
   
   # Install Python dependencies
   pip install pyyaml
   ```

2. **Configure AWS**:
   ```bash
   aws configure
   ```

3. **Run Terraform**:
   ```bash
   cd terraform
   terraform init
   terraform plan -var="instance_ids=[\"i-1234567890abcdef0\"]"
   terraform apply -var="instance_ids=[\"i-1234567890abcdef0\"]"
   ```

4. **Send Emails** (optional):
   ```bash
   # Send keys to test email (port 25, no auth)
   python3 scripts/send_keys.py \
     --smtp-host "mailhost.umb.com" \
     --smtp-port 25 \
     --keys-dir /tmp/ssh_keys \
     --test-email "saran.alla@umb.com"
   
   # Send keys to actual users (port 587, with auth)
   python3 scripts/send_keys.py \
     --smtp-host "smtp.gmail.com" \
     --smtp-port 587 \
     --smtp-user "your-email@gmail.com" \
     --smtp-pass "your-app-password" \
     --keys-dir /tmp/ssh_keys
   ```

## 🔧 Workflow Details

### GitHub Actions Workflow

The workflow consists of three main jobs:

1. **Validate**: Checks Terraform configuration and user YAML
2. **Provision Users**: Runs Terraform to create users and SSH keys
3. **Send Email Keys**: Emails private keys to users

### Terraform Process

1. **Read User Configuration**: Parses `users.yaml`
2. **Generate SSH Keys**: Creates unique key pairs for each user
3. **Connect to EC2**: Uses SSH to connect to each instance
4. **Create Users**: Adds Linux user accounts
5. **Setup SSH**: Configures authorized_keys for each user

### Email Process

1. **Load Keys**: Reads generated private keys from the keys directory
2. **Create Emails**: Generates personalized emails with complete information:
   - Username and full name
   - Instance details (ID, IP, type, region)
   - Complete SSH private key content
   - Security instructions and usage guide
3. **Send via SMTP**: Delivers emails using Python's smtplib module

## 🔒 Security Features

- **OIDC Authentication**: No long-term AWS credentials stored
- **Input Validation**: Instance IDs and regions are validated
- **Secure SSH Keys**: 4096-bit RSA keys with proper permissions
- **Secret Management**: All sensitive data uses GitHub secrets
- **Error Handling**: Comprehensive error handling with detailed messages
- **Timeout Management**: 10-minute timeout for plan, 15-minute for apply

## 🧪 Testing

### Validation Scripts

Run comprehensive validation:

```bash
# Quick validation (recommended)
bash scripts/quick_test.sh

# Full validation (requires Terraform setup)
bash scripts/test_workflow.sh
```

### Dry Run Mode

Test the workflow without making changes:

1. **GitHub Actions**: Enable "dry run" option when running workflow
2. **Local**: Set `dry_run = true` in Terraform variables
3. **Email Testing**: Use `--dry-run` flag with email script

### Validation Steps

The workflow includes several validation steps:

- ✅ Terraform syntax validation
- ✅ User YAML validation
- ✅ SSH connectivity testing
- ✅ Email template testing
- ✅ Security scanning
- ✅ Enterprise feature validation

## 📊 Monitoring and Troubleshooting

### Common Issues

#### **AWS Credentials Fail**
```bash
# Check OIDC role configuration
- Verify role exists: arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME
- Check role permissions for EC2 access
- Verify GitHub repository is configured for OIDC
```

#### **SSH Connection Failed**
```bash
# Check EC2 instance configuration
- Verify instances exist and are running
- Check instances have public IP addresses
- Validate SSH key file exists and is accessible
```

#### **Email Sending Fails**
```bash
# Check SMTP configuration
- Verify SMTP_HOST, SMTP_USER, SMTP_PASS secrets are set
- Test SMTP connection manually
- Check firewall rules for SMTP access
```

#### **User Already Exists**
```bash
# Workflow is idempotent - safe to re-run
- Existing users won't be duplicated
- SSH keys will be updated if changed
```

### Logs and Outputs

- **GitHub Actions**: Check workflow run logs
- **Terraform**: Review plan and apply outputs
- **Email Script**: Detailed sending logs with success/failure counts

## 🔄 Maintenance

### Adding New Users

1. Add user to `users.yaml`
2. Commit and push changes
3. Run workflow (existing users won't be affected)

### Removing Users

1. Remove user from `users.yaml`
2. Run workflow (existing users remain on instances)
3. Manually remove users from instances if needed

### Updating User Information

1. Update user details in `users.yaml`
2. Run workflow (only email will be updated)

## 📝 Example Commands

### Local Development

```bash
# Initialize Terraform
cd terraform
terraform init

# Plan with specific instances
terraform plan -var='instance_ids=["i-1234567890abcdef0"]'

# Apply changes
terraform apply -var='instance_ids=["i-1234567890abcdef0"]'

# Test email script
python3 ../scripts/send_keys.py \
  --smtp-host "smtp.gmail.com" \
  --smtp-user "admin@company.com" \
  --smtp-pass "app-password" \
  --dry-run
```

### GitHub Actions

```bash
# Trigger workflow manually
gh workflow run "Provision Users on AWS EC2 Instances" \
  -f instance_ids="i-1234567890abcdef0,i-0987654321fedcba0" \
  -f dry_run=true
```

## 🏢 Enterprise Features

### **Enterprise-Grade Security**
- ✅ OIDC-based AWS authentication
- ✅ Input validation and sanitization
- ✅ Secure SSH key generation
- ✅ Proper secret management
- ✅ Comprehensive error handling

### **Performance & Reliability**
- ✅ Timeout configurations for all operations
- ✅ Error recovery mechanisms
- ✅ Resource cleanup and management
- ✅ Detailed logging and monitoring

### **Monitoring & Observability**
- ✅ Detailed provisioning summary output
- ✅ Instance information capture
- ✅ User provisioning status tracking
- ✅ Artifact upload for audit trails

## ✅ Enterprise Readiness Status

**STATUS: PRODUCTION READY** ✅

The workflow has been thoroughly tested and validated to meet enterprise-grade standards:

- ✅ **Comprehensive error handling**
- ✅ **Secure credential management**
- ✅ **Input validation and sanitization**
- ✅ **Proper timeout management**
- ✅ **Detailed logging and monitoring**
- ✅ **Enterprise-grade security practices**

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 🆘 Support

For issues and questions:

1. Check the troubleshooting section above
2. Review GitHub Actions logs
3. Run validation scripts to identify issues
4. Open an issue with detailed error information
5. Include relevant configuration and error messages

---

**Note**: This project is designed for production use and has been thoroughly tested for enterprise environments. 
