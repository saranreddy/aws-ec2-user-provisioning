#!/bin/bash

echo "🧪 Testing New Workflow Approach"
echo "================================"

# Test 1: Generate SSH keys
echo "✅ Test 1: Generate SSH Keys"
mkdir -p /tmp/test_ssh_keys
if ssh-keygen -t rsa -b 4096 -f /tmp/test_ssh_keys/test_key -N "" -C "test@example.com"; then
    echo "   ✅ SSH key generation successful"
    mv /tmp/test_ssh_keys/test_key /tmp/test_ssh_keys/test_private_key
    mv /tmp/test_ssh_keys/test_key.pub /tmp/test_ssh_keys/test_public_key
else
    echo "   ❌ SSH key generation failed"
    exit 1
fi

# Test 2: Read public key content
echo "✅ Test 2: Read Public Key Content"
if [ -f "/tmp/test_ssh_keys/test_public_key" ]; then
    PUBLIC_KEY=$(cat "/tmp/test_ssh_keys/test_public_key")
    echo "   ✅ Public key content: ${PUBLIC_KEY:0:50}..."
else
    echo "   ❌ Public key file not found"
    exit 1
fi

# Test 3: Create terraform.tfvars (simplified)
echo "✅ Test 3: Create Simplified Terraform Variables"
cd terraform
cat > terraform.tfvars << EOF
instance_ids = ["i-test123"]
aws_region = "us-east-2"
dry_run = false
ssh_private_key_path = "~/.ssh/ec2-provisioning-key"
ssh_user = "ec2-user"
users_file = "../users.yaml"
EOF

if [ -f "terraform.tfvars" ]; then
    echo "   ✅ terraform.tfvars created successfully"
    echo "   📄 File contents:"
    cat terraform.tfvars
else
    echo "   ❌ terraform.tfvars creation failed"
    exit 1
fi

# Test 4: Validate Terraform configuration
echo "✅ Test 4: Validate Terraform Configuration"
if terraform validate; then
    echo "   ✅ Terraform configuration is valid"
else
    echo "   ❌ Terraform validation failed"
    exit 1
fi

# Cleanup
echo "🧹 Cleanup"
rm -rf /tmp/test_ssh_keys
rm -f terraform.tfvars
cd ..

echo ""
echo "🎉 All Tests Passed! The new workflow approach is working correctly."
echo "✅ SSH key generation: Working"
echo "✅ Key content reading: Working"
echo "✅ Terraform variables: Working"
echo "✅ Terraform validation: Working"
