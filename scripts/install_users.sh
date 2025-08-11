#!/bin/bash

# User Provisioning Script for EC2 Instances
# This script installs users and SSH keys on EC2 instances
# Usage: ./install_users.sh <user> <public_key> <ssh_user> <ec2_ip>

set -e  # Exit on any error

# Input validation
if [ $# -ne 4 ]; then
    echo "❌ Usage: $0 <user> <public_key> <ssh_user> <ec2_ip>"
    echo "   Example: $0 alice 'ssh-rsa AAAAB3NzaC1yc2E...' ec2-user 10.0.1.100"
    exit 1
fi

USER="$1"
PUBLIC_KEY="$2"
SSH_USER="$3"
EC2_IP="$4"

# Validate inputs
if [ -z "$USER" ] || [ -z "$PUBLIC_KEY" ] || [ -z "$SSH_USER" ] || [ -z "$EC2_IP" ]; then
    echo "❌ All parameters must be non-empty"
    exit 1
fi

echo "=== Installing User: $USER on EC2 Instance: $EC2_IP ==="

# Test SSH connection first
echo "🔍 Testing SSH connection to $EC2_IP..."
if ssh -i ~/.ssh/ec2-provisioning-key -o StrictHostKeyChecking=no -o ConnectTimeout=10 $SSH_USER@$EC2_IP "echo 'SSH connection successful'"; then
    echo "✅ SSH connection established"
else
    echo "❌ Failed to establish SSH connection"
    exit 1
fi

# Create user account
echo "👤 Creating user account for $USER..."
if ssh -i ~/.ssh/ec2-provisioning-key -o StrictHostKeyChecking=no $SSH_USER@$EC2_IP "sudo useradd -m -s /bin/bash $USER 2>/dev/null || echo 'User $USER already exists'"; then
    echo "✅ User account setup completed"
else
    echo "❌ Failed to setup user account"
    exit 1
fi

# Create .ssh directory with proper permissions
echo "📁 Setting up SSH directory for $USER..."
if ssh -i ~/.ssh/ec2-provisioning-key -o StrictHostKeyChecking=no $SSH_USER@$EC2_IP "sudo mkdir -p /home/$USER/.ssh && sudo chown $USER:$USER /home/$USER/.ssh && sudo chmod 700 /home/$USER/.ssh"; then
    echo "✅ SSH directory created with proper permissions"
else
    echo "❌ Failed to create SSH directory"
    exit 1
fi

# Install SSH public key
echo "🔑 Installing SSH key for $USER..."
if ssh -i ~/.ssh/ec2-provisioning-key -o StrictHostKeyChecking=no $SSH_USER@$EC2_IP "echo '$PUBLIC_KEY' | sudo tee -a /home/$USER/.ssh/authorized_keys && sudo chown $USER:$USER /home/$USER/.ssh/authorized_keys && sudo chmod 600 /home/$USER/.ssh/authorized_keys"; then
    echo "✅ SSH key installed successfully"
else
    echo "❌ Failed to install SSH key"
    exit 1
fi

# Verify the installation
echo "🔍 Verifying installation for $USER..."
if ssh -i ~/.ssh/ec2-provisioning-key -o StrictHostKeyChecking=no $SSH_USER@$EC2_IP "sudo test -f /home/$USER/.ssh/authorized_keys && sudo test -r /home/$USER/.ssh/authorized_keys"; then
    echo "✅ SSH key file verified and readable"
else
    echo "❌ SSH key file verification failed"
    exit 1
fi

# Test user SSH access
echo "🧪 Testing SSH access for $USER..."
# Create a temporary private key file for testing
TEMP_KEY="/tmp/test_${USER}_key"
if [ -f "/tmp/ssh_keys/${USER}_private_key" ]; then
    cp "/tmp/ssh_keys/${USER}_private_key" "$TEMP_KEY"
    chmod 600 "$TEMP_KEY"
    
    if ssh -i "$TEMP_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=10 $USER@$EC2_IP "echo 'User $USER can access EC2 successfully'"; then
        echo "✅ User $USER can access EC2 instance"
    else
        echo "❌ User $USER cannot access EC2 instance"
        rm -f "$TEMP_KEY"
        exit 1
    fi
    
    # Clean up temporary key
    rm -f "$TEMP_KEY"
else
    echo "⚠️  Private key not found for testing, skipping access verification"
fi

echo "🎉 User $USER successfully provisioned on EC2 instance $EC2_IP"
echo "✅ User account created"
echo "✅ SSH directory configured"
echo "✅ Public key installed"
echo "✅ Permissions set correctly"
echo "✅ SSH access verified"
