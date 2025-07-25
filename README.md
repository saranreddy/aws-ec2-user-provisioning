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

## 📁 Project Structure

```
aws-ec2-user-provisioning/
├── .github/
│   └── workflows/
│       └── provision-users.yml    # GitHub Actions workflow
├── terraform/
│   ├── main.tf                    # Main Terraform configuration
│   ├── variables.tf               # Input variables
│   ├── outputs.tf                 # Output definitions
│   └── keys/                      # Generated SSH keys (gitignored)
├── scripts/
│   └── send_keys.py               # Email script for SSH keys
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
- **EC2 Instances**: Running Amazon Linux 2 instances
- **SSH Access**: Private key to connect to EC2 instances
- **IAM Permissions**: Read access to EC2 instances

### Required GitHub Secrets
- `AWS_ACCESS_KEY_ID`: AWS access key
- `AWS_SECRET_ACCESS_KEY`: AWS secret key
- `SMTP_HOST`: SMTP server hostname
- `SMTP_USER`: SMTP username
- `SMTP_PASS`: SMTP password
- `SMTP_PORT`: SMTP port (optional, defaults to 587)

## 📋 Configuration

### 1. User Configuration (`users.yaml`)

Define users in the `users.yaml` file:

```yaml
users:
  - username: alice
    email: alice@example.com
    full_name: "Alice Johnson"
    
  - username: bob
    email: bob@example.com
    full_name: "Bob Smith"
```

### 2. Terraform Variables

Configure variables in `terraform/variables.tf` or pass them via command line:

```bash
# Required variables
instance_ids = ["i-1234567890abcdef0", "i-0987654321fedcba0"]

# Optional variables (with defaults)
aws_region = "us-west-2"
ssh_private_key_path = "~/.ssh/ec2-provisioning-key"
ssh_user = "ec2-user"
dry_run = false
```

## 🚀 Usage

### Method 1: GitHub Actions (Recommended)

1. **Fork/Clone** this repository
2. **Configure Secrets** in GitHub repository settings:
   - Go to Settings → Secrets and variables → Actions
   - Add all required secrets (AWS and SMTP credentials)
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
   python3 scripts/send_keys.py \
     --smtp-host "smtp.gmail.com" \
     --smtp-user "your-email@gmail.com" \
     --smtp-pass "your-app-password" \
     --users-file users.yaml \
     --terraform-dir terraform
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

1. **Load Keys**: Reads generated private keys
2. **Create Emails**: Generates personalized HTML/text emails
3. **Send via SMTP**: Delivers emails with SSH keys attached

## 🔒 Security Considerations

- **Private Keys**: Never commit private keys to version control
- **SSH Permissions**: Keys are stored with proper permissions (600)
- **Email Security**: Use secure SMTP with TLS
- **Access Control**: Limit who can trigger the workflow
- **Audit Trail**: GitHub Actions provides full audit logs

## 🧪 Testing

### Dry Run Mode

Test the workflow without making changes:

1. **GitHub Actions**: Enable "dry run" option when running workflow
2. **Local**: Set `dry_run = true` in Terraform variables
3. **Email Testing**: Use `--dry-run` flag with email script

### Validation

The workflow includes several validation steps:

- ✅ Terraform syntax validation
- ✅ User YAML validation
- ✅ SSH connectivity testing
- ✅ Email template testing

## 📊 Monitoring and Troubleshooting

### Common Issues

1. **SSH Connection Failed**:
   - Check EC2 instance is running
   - Verify SSH key path and permissions
   - Ensure security groups allow SSH access

2. **Email Delivery Failed**:
   - Verify SMTP credentials
   - Check email addresses are valid
   - Review SMTP server logs

3. **User Already Exists**:
   - Workflow is idempotent - safe to re-run
   - Existing users won't be duplicated

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
3. Open an issue with detailed error information
4. Include relevant configuration and error messages

---

**Note**: This project is designed for production use but should be thoroughly tested in your environment before deploying to production systems. 
