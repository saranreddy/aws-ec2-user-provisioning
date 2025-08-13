# Fortify Security Scan Troubleshooting Guide

## Overview
This guide helps you resolve common deployment errors when running the Fortify security scan workflow in GitHub Actions.

## Common Issues and Solutions

### 1. **Binary Not Found Errors**

**Problem**: `sourceanalyzer: command not found` or `fortifyclient: command not found`

**Root Cause**: Fortify binaries are not being installed to the correct location or with proper permissions.

**Solutions**:
- **Use the simplified workflow**: Replace your current `fortify-security-scan.yml` with `fortify-security-scan-simple.yml`
- **Check S3 component structure**: Ensure your S3 bucket has the correct Fortify component files
- **Verify file paths**: The workflow now dynamically finds binary locations instead of assuming fixed paths

### 2. **Disk Space Issues**

**Problem**: `Insufficient disk space` errors during installation

**Root Cause**: GitHub Actions runners have limited disk space, and Fortify components are large.

**Solutions**:
- **Cleanup previous runs**: The workflow now automatically cleans up before starting
- **Monitor disk usage**: Check the disk space verification step output
- **Use smaller scan levels**: Start with "basic" scan level to reduce resource usage

### 3. **S3 Download Failures**

**Problem**: `Failed to download Fortify components from S3`

**Root Cause**: Missing files in S3 bucket or incorrect file paths.

**Solutions**:
- **Verify S3 bucket structure**: Ensure your `aws-ec2-user-provisioning-security-files` bucket has:
  ```
  fortify/24.2.0/
  ├── components/
  │   ├── Fortify_SCA_24.2.0_Linux.tar.gz
  │   ├── Fortify_Tools_24.2.0_Linux.tar.gz
  │   ├── Fortify_ScanCentral_Controller_24.2.0.zip
  │   └── Fortify_SSC_Server_24.2.0.zip
  └── licenses/
      └── FortifySoftwareSecurityCenter24.2.0Licenses.zip
  ```
- **Check file permissions**: Ensure the GitHub Actions role has read access to the S3 bucket
- **Verify file names**: File names must match exactly (case-sensitive)

### 4. **Installation Permission Errors**

**Problem**: `Permission denied` when trying to execute Fortify binaries

**Root Cause**: Extracted files don't have executable permissions.

**Solutions**:
- **Automatic permission setting**: The simplified workflow automatically sets `chmod +x` on found binaries
- **Check file ownership**: Ensure files are owned by the GitHub Actions user
- **Verify extraction**: Check that files were extracted completely without corruption

### 5. **Scan Execution Failures**

**Problem**: Scan runs but fails to generate results or crashes

**Root Cause**: Incorrect scan parameters, missing source files, or binary incompatibility.

**Solutions**:
- **Use correct scan options**: The workflow provides appropriate options for each scan level
- **Check source directory**: Ensure the repository checkout contains the files you want to scan
- **Start with basic scan**: Use "basic" scan level first to test the setup

### 6. **Report Generation Failures**

**Problem**: Scan completes but reports are not generated

**Root Cause**: Missing ReportGenerator binary or incorrect parameters.

**Solutions**:
- **Check binary availability**: The workflow searches for ReportGenerator and handles missing cases gracefully
- **Verify FPR file**: Ensure the scan generated a valid `.fpr` file
- **Check permissions**: ReportGenerator binary needs execute permissions

## Step-by-Step Resolution Process

### Step 1: Replace the Workflow
```bash
# Backup your current workflow
cp .github/workflows/fortify-security-scan.yml .github/workflows/fortify-security-scan-backup.yml

# Use the simplified version
cp .github/workflows/fortify-security-scan-simple.yml .github/workflows/fortify-security-scan.yml
```

### Step 2: Verify S3 Components
```bash
# Check if your S3 bucket has the required files
aws s3 ls s3://aws-ec2-user-provisioning-security-files/fortify/24.2.0/components/ --recursive

# Verify file sizes (should be several MB each)
aws s3 ls s3://aws-ec2-user-provisioning-security-files/fortify/24.2.0/components/ --human-readable
```

### Step 3: Test with Basic Scan
1. Go to GitHub Actions → Fortify Security Scan
2. Click "Run workflow"
3. Select:
   - Scan Level: `basic`
   - AWS Account ID: `872515261591`
   - AWS Region: `us-east-2`
   - Email Notifications: `true`
4. Click "Run workflow"

### Step 4: Monitor the Execution
- Watch the workflow logs in real-time
- Pay attention to the "Verify Fortify Installation" step
- Check for any error messages in the "Download and Install Fortify Components" step

### Step 5: Check Results
If successful, you should see:
- ✅ Fortify installation verification completed
- ✅ Security scan completed successfully
- ✅ Scan results uploaded to S3
- Results available in your S3 bucket: `s3://fortify-scan-872515261591/scan-results/[timestamp]/`

## Debugging Commands

### Check S3 Bucket Contents
```bash
aws s3 ls s3://aws-ec2-user-provisioning-security-files/fortify/24.2.0/ --recursive --human-readable
```

### Verify GitHub Secrets
Ensure these secrets are set in your repository:
- `aws_ec2_creation_role` - The IAM role ARN for AWS access

### Test AWS Credentials
```bash
# Test if your role can access the S3 bucket
aws s3 ls s3://aws-ec2-user-provisioning-security-files/ --region us-east-2
```

## Common Error Messages and Solutions

| Error Message | Solution |
|---------------|----------|
| `Required secret 'aws_ec2_creation_role' is not set` | Set the secret in GitHub repository settings |
| `Insufficient disk space` | Wait for cleanup or use a fresh runner |
| `sourceanalyzer: command not found` | Use the simplified workflow that finds binaries dynamically |
| `Failed to download from S3` | Check S3 bucket structure and file names |
| `Permission denied` | The workflow now handles permissions automatically |
| `Scan failed - no results file generated` | Check scan parameters and source files |

## Getting Help

If you continue to experience issues:

1. **Check the workflow logs** for specific error messages
2. **Verify S3 bucket contents** match the expected structure
3. **Test with basic scan level** first
4. **Check GitHub Actions permissions** and secrets
5. **Review AWS IAM role permissions** for S3 access

## Success Indicators

Your Fortify scan is working correctly when you see:
- ✅ All installation steps complete without errors
- ✅ Binary verification shows found paths
- ✅ Scan execution completes and generates `.fpr` file
- ✅ Reports are generated and uploaded to S3
- ✅ Email notification is prepared
- ✅ Workflow completes with "Security scanning workflow completed successfully!"

## Next Steps After Successful Scan

1. **Review scan results** in the generated HTML report
2. **Analyze vulnerabilities** found in your code
3. **Address critical issues** identified by Fortify
4. **Schedule regular scans** by setting up automated triggers
5. **Integrate with CI/CD** for continuous security monitoring
