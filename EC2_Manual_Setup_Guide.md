# 🔑 Manual EC2 User Setup Guide
## AWS EC2 User Provisioning - Manual Setup Instructions

**Project:** AWS EC2 User Provisioning System  
**S3 Bucket:** `ec2-user-provisioning-keys-895583930163`  
**Target Instances:** 
- `i-0aa066000fb0bc430 - CAP360`
- `i-0401011455b52ea5e - BREAD-Interface`

**Date:** August 15, 2025  
**Version:** 1.0

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Step 1: Collect Public Keys from S3](#step-1-collect-public-keys-from-s3)
3. [Step 2: Setup Users on CAP360 Instance](#step-2-setup-users-on-cap360-instance)
4. [Step 3: Setup Users on BREAD-Interface Instance](#step-3-setup-users-on-bread-interface-instance)
5. [Step 4: Test User Access](#step-4-test-user-access)
6. [Troubleshooting](#troubleshooting)
7. [Verification Commands](#verification-commands)
8. [User List](#user-list)

---

## 🎯 Prerequisites

Before you begin, ensure you have the following:

- ✅ **AWS CLI Configured** with access to S3 bucket `ec2-user-provisioning-keys-895583930163`
- ✅ **SSH Access** to both EC2 instances (using your existing EC2 provisioning key)
- ✅ **Local Machine** with SSH client installed
- ✅ **EC2 Instance IP Addresses** for both instances
- ✅ **Administrative Access** on both EC2 instances

---

## 📥 Step 1: Collect Public Keys from S3

### 1.1 List Available Keys

First, verify that the keys are present in your S3 bucket:

```bash
aws s3 ls s3://ec2-user-provisioning-keys-895583930163/keys/
```

You should see a list of files like:
- `rai002_public_key`
- `rai002_private_key`
- `rai002_universal.pem`
- `hhe004_public_key`
- `hhe004_private_key`
- `hhe004_universal.pem`
- ... and so on for all 16 users

### 1.2 Download All Public Keys

```bash
# Create a directory for the keys
mkdir -p ~/ec2-user-keys
cd ~/ec2-user-keys

# Download all public keys for the 16 users
aws s3 cp s3://ec2-user-provisioning-keys-895583930163/keys/rai002_public_key ./
aws s3 cp s3://ec2-user-provisioning-keys-895583930163/keys/hhe004_public_key ./
aws s3 cp s3://ec2-user-provisioning-keys-895583930163/keys/rar010_public_key ./
aws s3 cp s3://ec2-user-provisioning-keys-895583930163/keys/sbe004_public_key ./
aws s3 cp s3://ec2-user-provisioning-keys-895583930163/keys/mac021_public_key ./
aws s3 cp s3://ec2-user-provisioning-keys-895583930163/keys/sra009_public_key ./
aws s3 cp s3://ec2-user-provisioning-keys-895583930163/keys/dje008_public_key ./
aws s3 cp s3://ec2-user-provisioning-keys-895583930163/keys/jbo005_public_key ./
aws s3 cp s3://ec2-user-provisioning-keys-895583930163/keys/cve002_public_key ./
aws s3 cp s3://ec2-user-provisioning-keys-895583930163/keys/sna006_public_key ./
aws s3 cp s3://ec2-user-provisioning-keys-895583930163/keys/msh012_public_key ./
aws s3 cp s3://ec2-user-provisioning-keys-895583930163/keys/nba005_public_key ./
aws s3 cp s3://ec2-user-provisioning-keys-895583930163/keys/dda007_public_key ./
aws s3 cp s3://ec2-user-provisioning-keys-895583930163/keys/sta003_public_key ./
aws s3 cp s3://ec2-user-provisioning-keys-895583930163/keys/txs030_public_key ./
```

**Verify Download:**
```bash
ls -la *_public_key
# Should show 16 public key files
```

---

## 🖥️ Step 2: Setup Users on CAP360 Instance

### 2.1 SSH into CAP360

```bash
ssh -i ~/.ssh/ec2-provisioning-key.pem ec2-user@<CAP360_IP_ADDRESS>
```

**Note:** Replace `<CAP360_IP_ADDRESS>` with the actual IP address of your CAP360 instance.

### 2.2 Create Users and Setup SSH Access

```bash
# Create all 16 users
sudo useradd -m rai002
sudo useradd -m hhe004
sudo useradd -m rar010
sudo useradd -m sbe004
sudo useradd -m mac021
sudo useradd -m sra009
sudo useradd -m dje008
sudo useradd -m jbo005
sudo useradd -m cve002
sudo useradd -m sna006
sudo useradd -m msh012
sudo useradd -m nba005
sudo useradd -m dda007
sudo useradd -m sta003
sudo useradd -m txs030

# Create .ssh directories and set permissions
for user in rai002 hhe004 rar010 sbe004 mac021 sra009 dje008 jbo005 cve002 sna006 msh012 nba005 dda007 sta003 txs030; do
    sudo mkdir -p /home/$user/.ssh
    sudo chown $user:$user /home/$user/.ssh
    sudo chmod 700 /home/$user/.ssh
done
```

### 2.3 Copy Public Keys to CAP360

From your **local machine** (open a new terminal):

```bash
# Copy all public keys to CAP360
scp -i ~/.ssh/ec2-provisioning-key.pem ~/ec2-user-keys/*_public_key ec2-user@<CAP360_IP_ADDRESS>:/tmp/
```

### 2.4 Setup authorized_keys on CAP360

Back on the **CAP360 instance**:

```bash
# For each user, append their public key to authorized_keys
for user in rai002 hhe004 rar010 sbe004 mac021 sra009 dje008 jbo005 cve002 sna006 msh012 nba005 dda007 sta003 txs030; do
    sudo cat /tmp/${user}_public_key >> /home/$user/.ssh/authorized_keys
    sudo chown $user:$user /home/$user/.ssh/authorized_keys
    sudo chmod 600 /home/$user/.ssh/authorized_keys
done

# Clean up temporary files
sudo rm /tmp/*_public_key
```

---

## 🖥️ Step 3: Setup Users on BREAD-Interface Instance

### 3.1 SSH into BREAD-Interface

```bash
ssh -i ~/.ssh/ec2-provisioning-key.pem ec2-user@10.18.248.193
```

**Note:** The IP address `10.18.248.193` was retrieved from previous workflow logs for BREAD-Interface.

### 3.2 Create Users and Setup SSH Access

```bash
# Create all 16 users
sudo useradd -m rai002
sudo useradd -m hhe004
sudo useradd -m rar010
sudo useradd -m sbe004
sudo useradd -m mac021
sudo useradd -m sra009
sudo useradd -m dje008
sudo useradd -m jbo005
sudo useradd -m cve002
sudo useradd -m sna006
sudo useradd -m msh012
sudo useradd -m nba005
sudo useradd -m dda007
sudo useradd -m sta003
sudo useradd -m txs030

# Create .ssh directories and set permissions
for user in rai002 hhe004 rar010 sbe004 mac021 sra009 dje008 jbo005 cve002 sna006 msh012 nba005 dda007 sta003 txs030; do
    sudo mkdir -p /home/$user/.ssh
    sudo chown $user:$user /home/$user/.ssh
    sudo chmod 700 /home/$user/.ssh
done
```

### 3.3 Copy Public Keys to BREAD-Interface

From your **local machine** (open a new terminal):

```bash
# Copy all public keys to BREAD-Interface
scp -i ~/.ssh/ec2-provisioning-key.pem ~/ec2-user-keys/*_public_key ec2-user@10.18.248.193:/tmp/
```

### 3.4 Setup authorized_keys on BREAD-Interface

Back on the **BREAD-Interface instance**:

```bash
# For each user, append their public key to authorized_keys
for user in rai002 hhe004 rar010 sbe004 mac021 sra009 dje008 jbo005 cve002 sna006 msh012 nba005 dda007 sta003 txs030; do
    sudo cat /tmp/${user}_public_key >> /home/$user/.ssh/authorized_keys
    sudo chown $user:$user /home/$user/.ssh/authorized_keys
    sudo chmod 600 /home/$user/.ssh/authorized_keys
done

# Clean up temporary files
sudo rm /tmp/*_public_key
```

---

## 🧪 Step 4: Test User Access

### 4.1 Download Private Keys for Testing

```bash
cd ~/ec2-user-keys

# Download private keys for testing
aws s3 cp s3://ec2-user-provisioning-keys-895583930163/keys/sta003_private_key ./
aws s3 cp s3://ec2-user-provisioning-keys-895583930163/keys/txs030_private_key ./
aws s3 cp s3://ec2-user-provisioning-keys-895583930163/keys/rai002_private_key ./

# Set proper permissions
chmod 400 *_private_key
```

### 4.2 Test Access to CAP360

```bash
# Test sta003 access to CAP360
ssh -i sta003_private_key sta003@<CAP360_IP_ADDRESS>

# Test txs030 access to CAP360
ssh -i txs030_private_key txs030@<CAP360_IP_ADDRESS>

# Test rai002 access to CAP360
ssh -i rai002_private_key rai002@<CAP360_IP_ADDRESS>
```

### 4.3 Test Access to BREAD-Interface

```bash
# Test sta003 access to BREAD-Interface
ssh -i sta003_private_key sta003@10.18.248.193

# Test txs030 access to BREAD-Interface
ssh -i txs030_private_key txs030@10.18.248.193

# Test rai002 access to BREAD-Interface
ssh -i rai002_private_key rai002@10.18.248.193
```

---

## ✅ Success Indicators

### 🎯 Successful Login

- You'll see a shell prompt like: `sta003@ip-10-18-248-193:~$`
- You can run commands like `whoami`, `pwd`, `ls -la`
- The user has full access to their home directory

### ❌ Common Issues & Solutions

#### Permission Denied

```bash
# Check permissions on the instance
sudo ls -la /home/sta003/.ssh/
sudo cat /home/sta003/.ssh/authorized_keys

# Fix permissions if needed
sudo chmod 700 /home/sta003/.ssh
sudo chmod 600 /home/sta003/.ssh/authorized_keys
sudo chown sta003:sta003 /home/sta003/.ssh/authorized_keys
```

#### Connection Refused

- Verify the instance is running
- Check security group allows SSH (port 22)
- Verify you're using the correct IP address
- Ensure the instance is accessible from your network

#### No Such File or Directory

```bash
# Create missing directories
sudo mkdir -p /home/sta003/.ssh
sudo chown sta003:sta003 /home/sta003/.ssh
sudo chmod 700 /home/sta003/.ssh
```

#### Key Format Issues

```bash
# Verify the public key format
cat sta003_public_key
# Should start with "ssh-rsa" and end with a comment

# Check if the key was properly appended
sudo cat /home/sta003/.ssh/authorized_keys
# Should contain the public key content
```

---

## 🔍 Verification Commands

### On Each Instance, Verify Setup

```bash
# Check all users exist
sudo cat /etc/passwd | grep -E "(rai002|hhe004|rar010|sbe004|mac021|sra009|dje008|jbo005|cve002|sna006|msh012|nba005|dda007|sta003|txs030)"

# Check .ssh directories
sudo ls -la /home/*/.ssh/

# Check authorized_keys files
sudo ls -la /home/*/.ssh/authorized_keys

# Verify permissions
sudo find /home/*/.ssh -type d -exec ls -ld {} \;
sudo find /home/*/.ssh -name "authorized_keys" -exec ls -l {} \;
```

### Test File Creation

```bash
# Test as each user (example for sta003)
sudo su - sta003
echo "Test file created at $(date)" > ~/test_access.txt
ls -la ~/test_access.txt
cat ~/test_access.txt
exit
```

---

## 👥 User List

| Username | Full Name | Email |
|----------|-----------|-------|
| rai002 | Raghavee A | raghavee.ai@umb.com |
| hhe004 | Harsha-Venkatraman Hegde | harsha-venkatraman.hegde@umb.com |
| rar010 | Aravind Ramesh | ramesh.aravind@umb.com |
| sbe004 | Shamshath Begam | shamshath.begam@umb.com |
| mac021 | Minakshi Achary | minakshi.achary@umb.com |
| sra009 | Sakkaravarthi Ramasubbu | sakkaravarthi.ramasubbu@umb.com |
| dje008 | Deborah Jerusha | deborah.jerusha@umb.com |
| jbo005 | Juanita Booheister | juanita.booheister@umb.com |
| cve002 | Chandrasekar Venkatesan | chandrasekar.venkatesan@umb.com |
| sna006 | Shruti Nallari | shruti.nallari@umb.com |
| msh012 | Monika Sharma | monika.sharma@umb.com |
| nba005 | Namitha Barthur | namitha.barthur@umb.com |
| dda007 | Daison Aloor David | daison.david@umb.com |
| sta003 | Saran Alla | saran.alla@umb.com |
| txs030 | TJ | tripatjeet.singh@umb.com |

**Total Users:** 16

---

## 📝 Summary

### What This Guide Accomplishes

1. **Downloads public keys** from S3 bucket `ec2-user-provisioning-keys-895583930163`
2. **Sets up users** on both CAP360 and BREAD-Interface instances
3. **Copies public keys** to each instance
4. **Tests access** using private keys from S3
5. **Verifies** all 16 users can access both instances

### Workflow Integration

This manual setup completes what the GitHub Actions workflow started:
- ✅ **SSH keys generated** and stored in S3
- ✅ **Emails sent** to users with their private keys
- ✅ **Manual EC2 setup** (this guide)
- ✅ **User access verified** and tested

### Next Steps

After completing this setup:
1. **Users can connect** using their private keys
2. **Access is secure** and key-based
3. **Keys are persistent** in S3 for future use
4. **System is production-ready** for all 16 users

---

## 🚨 Important Notes

- **Keep private keys secure** - never share or commit to version control
- **Monitor access logs** on both instances
- **Regular security audits** of user access
- **Backup authorized_keys** files for disaster recovery
- **Document any customizations** made during setup

---

## 📞 Support

If you encounter issues during setup:
1. Check the troubleshooting section above
2. Verify all prerequisites are met
3. Review the verification commands
4. Contact your system administrator

---

**Document Version:** 1.0  
**Last Updated:** August 15, 2025  
**Author:** AWS EC2 User Provisioning System  
**Status:** Ready for Implementation
