#!/bin/bash

# Example script for running AWS EC2 User Provisioning locally
# This script demonstrates how to use the project

set -e  # Exit on any error

echo "🚀 AWS EC2 User Provisioning - Example Run"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Check if required tools are installed
check_dependencies() {
    print_status "Checking dependencies..."
    
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is not installed. Please install Python 3 first."
        exit 1
    fi
    
    if ! command -v aws &> /dev/null; then
        print_warning "AWS CLI is not installed. You may need it for AWS authentication."
    fi
    
    print_success "Dependencies check completed"
}

# Install Python dependencies
install_python_deps() {
    print_status "Installing Python dependencies..."
    
    if [ -f "scripts/requirements.txt" ]; then
        pip3 install -r scripts/requirements.txt
        print_success "Python dependencies installed"
    else
        print_warning "requirements.txt not found, installing PyYAML manually"
        pip3 install PyYAML
    fi
}

# Initialize Terraform
init_terraform() {
    print_status "Initializing Terraform..."
    
    cd terraform
    
    # Check if terraform.tfvars exists
    if [ ! -f "terraform.tfvars" ]; then
        print_warning "terraform.tfvars not found. Please create it from terraform.tfvars.example"
        print_status "Example command:"
        echo "  cp terraform.tfvars.example terraform.tfvars"
        echo "  # Then edit terraform.tfvars with your instance IDs"
        cd ..
        return 1
    fi
    
    terraform init
    print_success "Terraform initialized"
    cd ..
}

# Run Terraform plan
run_terraform_plan() {
    print_status "Running Terraform plan..."
    
    cd terraform
    terraform plan
    cd ..
    
    print_success "Terraform plan completed"
}

# Run Terraform apply
run_terraform_apply() {
    print_status "Running Terraform apply..."
    
    cd terraform
    terraform apply -auto-approve
    cd ..
    
    print_success "Terraform apply completed"
}

# Test email script
test_email_script() {
    print_status "Testing email script..."
    
    # Check if SMTP environment variables are set
    if [ -z "$SMTP_HOST" ] || [ -z "$SMTP_USER" ] || [ -z "$SMTP_PASS" ]; then
        print_warning "SMTP environment variables not set. Skipping email test."
        print_status "To test emails, set these environment variables:"
        echo "  export SMTP_HOST='smtp.gmail.com'"
        echo "  export SMTP_USER='your-email@gmail.com'"
        echo "  export SMTP_PASS='your-app-password'"
        return 0
    fi
    
    python3 scripts/send_keys.py \
        --smtp-host "$SMTP_HOST" \
        --smtp-port "$SMTP_PORT" \
        --smtp-user "$SMTP_USER" \
        --smtp-pass "$SMTP_PASS" \
        --dry-run \
        --users-file users.yaml \
        --keys-dir /tmp/ssh_keys
    
    print_success "Email script test completed"
}

# Main execution
main() {
    echo ""
    print_status "Starting AWS EC2 User Provisioning example..."
    
    # Check dependencies
    check_dependencies
    
    # Install Python dependencies
    install_python_deps
    
    # Initialize Terraform
    if ! init_terraform; then
        print_error "Terraform initialization failed. Please check your configuration."
        exit 1
    fi
    
    # Ask user if they want to proceed
    echo ""
    read -p "Do you want to run Terraform plan? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        run_terraform_plan
        
        echo ""
        read -p "Do you want to apply the changes? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            run_terraform_apply
            
            echo ""
            read -p "Do you want to test the email script? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                test_email_script
            fi
        fi
    fi
    
    echo ""
    print_success "Example run completed!"
    echo ""
    print_status "Next steps:"
    echo "  1. Review the generated SSH keys in terraform/keys/"
    echo "  2. Check that users were created on your EC2 instances"
    echo "  3. Test SSH connections with the generated keys"
    echo "  4. Run the email script to send keys to users"
    echo ""
    print_status "For more information, see README.md"
}

# Run main function
main "$@" 