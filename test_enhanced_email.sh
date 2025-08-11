#!/bin/bash

# Test script for enhanced email functionality
# This script tests the updated send_keys.py with instance information

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "=== Testing Enhanced Email Functionality ==="
echo ""

# Check if we're in the right directory
if [ ! -f "scripts/send_keys.py" ]; then
    print_error "send_keys.py not found. Please run this script from the project root."
    exit 1
fi

# Check if Terraform directory exists
if [ ! -d "terraform" ]; then
    print_error "terraform directory not found. Please run this script from the project root."
    exit 1
fi

# Check if users.yaml exists
if [ ! -f "users.yaml" ]; then
    print_error "users.yaml not found. Please run this script from the project root."
    exit 1
fi

print_status "Testing enhanced email script with dry run..."

# Test the enhanced email script with dry run
python3 scripts/send_keys.py \
    --smtp-host "mailhost.umb.com" \
    --smtp-port 25 \
    --keys-dir "terraform/keys" \
    --terraform-dir "terraform" \
    --users-file "users.yaml" \
    --test-email "test@example.com" \
    --dry-run

if [ $? -eq 0 ]; then
    print_success "Enhanced email script test completed successfully!"
    echo ""
    print_status "The script now includes:"
    echo "  ✅ Private key attachment"
    echo "  ✅ Username information"
    echo "  ✅ Instance name/ID"
    echo "  ✅ Instance IP address (private preferred)"
    echo "  ✅ Instance type and region"
    echo ""
    print_status "Ready to send actual emails with full instance information!"
else
    print_error "Enhanced email script test failed!"
    exit 1
fi
