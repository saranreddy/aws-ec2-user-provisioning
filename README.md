# 🚀 AWS EC2 User Provisioning System

A comprehensive, automated system for provisioning users on AWS EC2 instances with secure SSH key management and intelligent email delivery.

## ✨ Features

### 🔐 **Secure User Management**
- **Automated user creation** on AWS EC2 instances
- **SSH key generation** and distribution
- **Individual user emails** - each user receives their key at their own email address
- **Key persistence** - existing users maintain access across workflow runs

### 📧 **Smart Email System**
- **Python-based SMTP** implementation for reliability
- **Private keys as attachments** for easy download
- **Selective email delivery** - only new users receive emails
- **Complete information** - private key, IP address, instance name, user ID

### 🏗️ **Infrastructure Management**
- **Terraform automation** for EC2 provisioning
- **GitHub Actions workflow** with Docker runner
- **S3 key storage** with persistence across runs
- **Comprehensive logging** and error handling

## 🎯 **How It Works**

### **1. User Provisioning**
- Reads user configuration from `users.yaml`
- Generates unique SSH key pairs for each user
- Creates user accounts on EC2 instances
- Installs public keys for SSH access

### **2. Key Management**
- **Fixed S3 bucket** (`ec2-user-provisioning-keys`) for key persistence
- **Existing users**: Keys preserved, no regeneration
- **New users**: New keys generated and stored
- **Automatic key rotation** when needed

### **3. Email Delivery**
- **New users**: Receive complete email with key attachment
- **Existing users**: No emails sent (they already have access)
- **Individual delivery**: Each user gets their key at their own email address
- **Professional formatting** with complete instructions

## 🚀 **Quick Start**

### **Prerequisites**
- AWS CLI configured with appropriate permissions
- GitHub repository with Actions enabled
- EC2 instance running with SSH access

### **1. Configure Users**
Edit `users.yaml` to define your users:

```yaml
users:
- username: sta003
  email: saran.alla@umb.com
  full_name: "Saran Alla"

- username: txs030
  email: Tripatjeet.Singh@umb.com
  full_name: "TJ"
```

### **2. Set GitHub Secrets**
Configure these secrets in your GitHub repository:

```
AWS_EC2_CREATION_ROLE=your-iam-role-name
EC2_SSH_PRIVATE_KEY=your-ec2-ssh-private-key
```

### **3. Run the Workflow**
1. Go to **Actions** tab in your GitHub repository
2. Select **"Provision Users on AWS EC2 Instances"**
3. Click **"Run workflow"**
4. Configure parameters:
   - **Instance ID**: Select your EC2 instance
   - **AWS Account ID**: Your AWS account ID
   - **AWS Region**: Your instance region
   - **Send Emails**: Enable to send SSH keys via email

## 🔧 **Workflow Details**

### **Jobs Overview**
1. **Setup & Authentication**: AWS credentials and Terraform setup
2. **User Provisioning**: Create users and generate SSH keys
3. **Key Management**: Store keys in S3 with persistence
4. **Email Delivery**: Send keys to new users only
5. **Verification**: Test SSH access for all users

### **Key Persistence Logic**
```
First Run:
├── Create S3 bucket: ec2-user-provisioning-keys
├── Generate keys for all users
└── Upload keys to S3

Subsequent Runs:
├── Check existing keys in S3
├── Download existing keys (preserve access)
├── Generate new keys only for new users
└── Send emails only to new users
```

### **Email Intelligence**
- **New Users**: Full email with key attachment and instructions
- **Existing Users**: No email sent (access maintained)
- **Status Tracking**: Clear logging of who got emails and why

## 📁 **Project Structure**

```
aws-ec2-user-provisioning/
├── .github/workflows/
│   └── provision-users.yml    # Main workflow
├── scripts/
│   ├── install_users.sh       # User installation script
│   ├── send_keys.py          # Email delivery script
│   └── run_example.sh        # Example usage script
├── terraform/
│   ├── main.tf               # EC2 instance configuration
│   ├── variables.tf          # Variable definitions
│   └── outputs.tf            # Output values
├── users.yaml                # User configuration
└── README.md                 # This file
```

## 🔒 **Security Features**

### **SSH Key Management**
- **4096-bit RSA keys** for strong encryption
- **Individual key pairs** for each user
- **Secure S3 storage** with AES256 encryption
- **Proper file permissions** (chmod 600)

### **Access Control**
- **IAM role-based authentication** for AWS operations
- **SSH key-based authentication** for EC2 access
- **User isolation** with separate home directories
- **Audit logging** for all operations

## 📧 **Email System**

### **SMTP Configuration**
- **Server**: `mailhost.umb.com:25`
- **Authentication**: None required (port 25)
- **Encryption**: TLS when supported
- **Fallback**: Graceful handling of connection issues

### **Email Content**
- **User Information**: Username, full name, generation timestamp
- **Instance Details**: ID, IP address, name, region
- **Private Key**: Attached as downloadable file
- **Usage Instructions**: Step-by-step connection guide
- **Security Guidelines**: Best practices and warnings

## 🧪 **Testing & Verification**

### **Dry Run Mode**
Enable dry run to test without making changes:
- No actual user creation
- No key generation
- No email sending
- Full workflow validation

### **Verification Process**
- **SSH Connection Test**: Verify each user can connect
- **File Operations**: Test read/write permissions
- **Key Authentication**: Validate SSH key functionality
- **User Environment**: Check home directory access

## 🚨 **Troubleshooting**

### **Common Issues**

**SMTP Connection Failed**
- Check network connectivity to mailhost.umb.com
- Verify port 25 is not blocked
- Check firewall settings

**User Access Denied**
- Verify SSH key permissions (chmod 600)
- Check EC2 security group settings
- Confirm user exists on instance

**S3 Upload Failed**
- Verify AWS credentials and permissions
- Check S3 bucket creation permissions
- Ensure region configuration is correct

### **Debug Information**
The workflow provides comprehensive logging:
- **User processing status**
- **Key generation details**
- **S3 operation results**
- **Email delivery status**
- **Verification results**

## 📈 **Monitoring & Maintenance**

### **Workflow Monitoring**
- **GitHub Actions logs** for detailed execution history
- **S3 bucket contents** for key inventory
- **Email delivery reports** for communication tracking
- **User access verification** for security monitoring

### **Regular Maintenance**
- **Review user list** in `users.yaml`
- **Monitor S3 bucket** for key storage
- **Check email delivery** success rates
- **Verify user access** on EC2 instances

## 🤝 **Contributing**

### **Development Workflow**
1. **Fork the repository**
2. **Create feature branch**
3. **Make changes** with proper testing
4. **Submit pull request** with detailed description

### **Testing Requirements**
- **Test workflow execution** in dry run mode
- **Verify email delivery** functionality
- **Check key persistence** across multiple runs
- **Validate user access** on test instances

## 📄 **License**

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 **Support**

### **Getting Help**
- **Check troubleshooting section** above
- **Review workflow logs** in GitHub Actions
- **Examine error messages** for specific issues
- **Verify configuration** in users.yaml and secrets

### **Feature Requests**
- **Submit issues** for bugs or problems
- **Request enhancements** for new functionality
- **Share use cases** for improvement ideas

---

**Built with ❤️ for secure, automated AWS user management**

*Last updated: August 2025* 

## 🚀 **Dynamic Instance Discovery**

The workflow now automatically discovers running EC2 instances instead of requiring hardcoded instance IDs.

### **How It Works:**

1. **Smart Discovery**: Queries AWS for running instances in the specified region
2. **Tag-Based Filtering**: First tries to find instances tagged with `UserProvisioning: true`
3. **Fallback Strategy**: If no tagged instances found, discovers all running instances
4. **Automatic Selection**: Uses the first discovered instance for user provisioning

### **Instance Tagging (Optional but Recommended):**

```yaml
Tags:
  - Key: UserProvisioning
    Value: true
  
  - Key: Environment
    Value: production
  
  - Key: Name
    Value: WebServer-01
```

### **Benefits:**

- ✅ **No Manual Maintenance**: No need to update hardcoded instance IDs
- ✅ **Real-Time Accuracy**: Always shows current running instances
- ✅ **Professional Workflow**: Enterprise-grade automation
- ✅ **Scalable**: Handles new instances automatically
- ✅ **Smart Fallback**: Works even without proper tagging

### **Discovery Process:**

```
🔍 Query AWS for running instances
📋 Check for UserProvisioning tag
🔄 Fallback to all running instances if needed
✅ Present dynamic list to user
🎯 Use first instance for provisioning
```

## 📧 **Email Process** 
