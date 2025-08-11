# Troubleshooting Guide: SSH Key Generation and S3 Upload Failure

## Problem Description
The GitHub Actions workflow "Provision Users on AWS EC2 Instances" is failing at the "Generate and Upload SSH Keys to S3" step with exit code 252.

## Root Causes
Exit code 252 typically indicates one of these issues:

1. **S3 Bucket Creation Permission Denied**
   - The AWS role `aws_ec2_creation_role` lacks `s3:CreateBucket` permission
   - Bucket name conflicts (globally unique requirement)

2. **S3 Object Upload Permission Denied**
   - Missing `s3:PutObject` permission
   - Missing `s3:ListBucket` permission

3. **SSH Key Generation Issues**
   - `openssh-client` package not available
   - Insufficient disk space in `/tmp`
   - Permission issues in temporary directory

4. **AWS Credentials/Authentication Issues**
   - Role assumption failure
   - Expired credentials
   - Incorrect role ARN

## Applied Fixes

### 1. Enhanced Error Handling
- Added detailed error messages for each failure point
- Implemented fallback bucket naming strategy
- Added permission testing before operations

### 2. Permission Validation
- Added new step "Check Required AWS Permissions" that tests:
  - S3 bucket creation
  - Object upload/download
  - Object listing
- Provides clear feedback on missing permissions

### 3. Robust Bucket Management
- Uses timestamped bucket names to avoid conflicts
- Fallback to alternative bucket names
- Option to use existing bucket via `EXISTING_S3_BUCKET` environment variable

### 4. SSH Key Generation Improvements
- Ensures `openssh-client` package is installed
- Checks disk space and permissions before generation
- Better error handling for key generation failures

### 5. S3 Upload Enhancements
- Individual error handling for each upload operation
- Detailed logging of upload progress
- Verification of upload success

## Required AWS Permissions

The role `aws_ec2_creation_role` needs these S3 permissions:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:CreateBucket",
                "s3:PutObject",
                "s3:GetObject",
                "s3:ListBucket",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::ec2-user-provisioning-*",
                "arn:aws:s3:::ec2-user-provisioning-*/*"
            ]
        }
    ]
}
```

## Quick Fixes

### Option 1: Use Existing Bucket
Set the `EXISTING_S3_BUCKET` environment variable in your repository:
1. Go to Settings → Secrets and variables → Actions
2. Add repository variable: `EXISTING_S3_BUCKET` = `your-existing-bucket-name`

### Option 2: Update IAM Role Permissions
Add the required S3 permissions to your `aws_ec2_creation_role`:
1. Go to AWS IAM Console
2. Find the role `aws_ec2_creation_role`
3. Attach a policy with the S3 permissions listed above

### Option 3: Create Dedicated S3 Bucket
Manually create an S3 bucket and update the workflow:
1. Create bucket: `ec2-user-provisioning-<your-account-id>`
2. Set `EXISTING_S3_BUCKET` to this bucket name

## Testing the Fix

After applying the fixes:

1. **Re-run the workflow** with the same parameters
2. **Check the logs** for the new permission validation step
3. **Verify S3 bucket creation** or existing bucket access
4. **Monitor SSH key generation** progress

## Expected Behavior

With the fixes applied, you should see:
- ✅ Permission checks pass
- ✅ S3 bucket creation/access successful
- ✅ SSH key generation for all users
- ✅ Successful upload to S3
- ✅ Clean temporary file cleanup

## Debugging Steps

If issues persist:

1. **Check AWS Role Permissions**: Verify the role has all required S3 permissions
2. **Review CloudTrail Logs**: Look for permission denied errors
3. **Test Manually**: Try the same operations manually with the same role
4. **Check Region**: Ensure the S3 bucket is created in the correct region

## Support

If you continue to experience issues:
1. Check the detailed error logs in the GitHub Actions run
2. Verify your AWS role configuration
3. Ensure your AWS account has S3 service enabled
4. Check for any AWS service quotas or limits
