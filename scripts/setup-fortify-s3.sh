#!/bin/bash

# Fortify S3 Setup Script
# This script helps set up the S3 bucket structure for Fortify installation files

set -e

# Configuration
DEFAULT_BUCKET_NAME="fortify-installation-files"
DEFAULT_REGION="us-east-2"
DEFAULT_FORTIFY_VERSION="24.2.0"

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

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -b, --bucket-name NAME    S3 bucket name (default: $DEFAULT_BUCKET_NAME)
    -r, --region REGION       AWS region (default: $DEFAULT_REGION)
    -v, --version VERSION     Fortify version (default: $DEFAULT_FORTIFY_VERSION)
    -h, --help               Show this help message

Examples:
    $0                                    # Use all defaults
    $0 -b my-fortify-bucket              # Custom bucket name
    $0 -r us-west-2 -v 24.2.1           # Custom region and version

EOF
}

# Parse command line arguments
BUCKET_NAME="$DEFAULT_BUCKET_NAME"
REGION="$DEFAULT_REGION"
FORTIFY_VERSION="$DEFAULT_FORTIFY_VERSION"

while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--bucket-name)
            BUCKET_NAME="$2"
            shift 2
            ;;
        -r|--region)
            REGION="$2"
            shift 2
            ;;
        -v|--version)
            FORTIFY_VERSION="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

print_status "Fortify S3 Setup Script"
print_status "========================="
echo ""

print_status "Configuration:"
echo "  - S3 Bucket: $BUCKET_NAME"
echo "  - AWS Region: $REGION"
echo "  - Fortify Version: $FORTIFY_VERSION"
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials are not configured. Please run 'aws configure' first."
    exit 1
fi

print_success "AWS CLI and credentials verified"
echo ""

# Create S3 bucket if it doesn't exist
print_status "Creating S3 bucket: $BUCKET_NAME"
if aws s3 ls "s3://$BUCKET_NAME" 2>&1 > /dev/null; then
    print_warning "Bucket $BUCKET_NAME already exists"
else
    if aws s3 mb "s3://$BUCKET_NAME" --region "$REGION"; then
        print_success "Bucket $BUCKET_NAME created successfully"
    else
        print_error "Failed to create bucket $BUCKET_NAME"
        exit 1
    fi
fi

# Create bucket structure
print_status "Creating bucket structure..."
aws s3api put-object --bucket "$BUCKET_NAME" --key "fortify-$FORTIFY_VERSION/"
aws s3api put-object --bucket "$BUCKET_NAME" --key "license/"
aws s3api put-object --bucket "$BUCKET_NAME" --key "config/"
aws s3api put-object --bucket "$BUCKET_NAME" --key "scan-results/"
print_success "Bucket structure created"
echo ""

# Create README file with instructions
print_status "Creating README with setup instructions..."
cat > /tmp/fortify-s3-setup.md << EOF
# Fortify S3 Setup Instructions

## Required Files

To use this S3 bucket with the Fortify GitHub Actions workflow, you need to upload the following files:

### 1. Fortify Installation Files
Upload these files to: \`s3://$BUCKET_NAME/fortify-$FORTIFY_VERSION/\`

- \`Fortify_SCA_and_Apps_$FORTIFY_VERSION\_linux_x64.run\`
- \`Fortify_ScanCentral_$FORTIFY_VERSION\_linux_x64.run\`

### 2. License File
Upload your Fortify license file to: \`s3://$BUCKET_NAME/license/\`

- \`fortify.license\`

### 3. Configuration Files (Optional)
Upload any configuration files to: \`s3://$BUCKET_NAME/config/\`

## Upload Commands

\`\`\`bash
# Upload Fortify installers
aws s3 cp Fortify_SCA_and_Apps_$FORTIFY_VERSION\_linux_x64.run s3://$BUCKET_NAME/fortify-$FORTIFY_VERSION/
aws s3 cp Fortify_ScanCentral_$FORTIFY_VERSION\_linux_x64.run s3://$BUCKET_NAME/fortify-$FORTIFY_VERSION/

# Upload license
aws s3 cp fortify.license s3://$BUCKET_NAME/license/

# Upload any config files
aws s3 cp fortify.conf s3://$BUCKET_NAME/config/
\`\`\`

## GitHub Actions Usage

In your GitHub Actions workflow, use these parameters:

\`\`\`yaml
- name: Fortify Security Scan
  uses: ./.github/workflows/fortify-scan.yml
  with:
    s3_bucket: "$BUCKET_NAME"
    fortify_version: "$FORTIFY_VERSION"
    scan_type: "source-code"
\`\`\`

## Security Notes

- Ensure your S3 bucket has appropriate access controls
- The GitHub Actions workflow will use the same AWS credentials as this setup
- Scan results will be uploaded to \`s3://$BUCKET_NAME/scan-results/\`
EOF

aws s3 cp /tmp/fortify-s3-setup.md "s3://$BUCKET_NAME/README.md"
rm -f /tmp/fortify-s3-setup.md
print_success "README created and uploaded"
echo ""

# Show current bucket contents
print_status "Current bucket contents:"
aws s3 ls "s3://$BUCKET_NAME" --recursive --human-readable
echo ""

# Show next steps
print_status "Next Steps:"
echo "1. Download Fortify $FORTIFY_VERSION installers from the official Fortify portal"
echo "2. Upload the .run files to: s3://$BUCKET_NAME/fortify-$FORTIFY_VERSION/"
echo "3. Upload your Fortify license to: s3://$BUCKET_NAME/license/"
echo "4. Test the GitHub Actions workflow with the 'source-code' scan type"
echo ""
print_warning "Note: The workflow will fail until you upload the required Fortify files"
echo ""

print_success "S3 bucket setup completed successfully!"
print_status "Bucket: s3://$BUCKET_NAME"
print_status "Region: $REGION"
print_status "Fortify Version: $FORTIFY_VERSION"
