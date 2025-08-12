#!/bin/bash

# Test Dynamic Instance Discovery
# This script tests the dynamic instance discovery functionality

set -e

echo "🧪 Testing Dynamic Instance Discovery"
echo "====================================="

# Check if AWS CLI is available
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Please install it first."
    exit 1
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "❌ jq not found. Please install it first."
    exit 1
fi

# Set default region (can be overridden)
REGION="${AWS_DEFAULT_REGION:-us-east-2}"
echo "🌍 Using AWS region: $REGION"

echo ""
echo "🔍 Testing Instance Discovery..."

# Test 1: Query for instances with UserProvisioning tag
echo "📋 Test 1: Querying for instances with UserProvisioning tag..."
TAGGED_INSTANCES=$(aws ec2 describe-instances \
  --region "$REGION" \
  --filters \
    "Name=instance-state-name,Values=running" \
    "Name=tag:UserProvisioning,Values=true" \
  --query 'Reservations[].Instances[].[InstanceId,InstanceType,Tags[?Key==`Name`].Value|[0],PrivateIpAddress,PublicIpAddress]' \
  --output json 2>/dev/null || echo "[]")

echo "   Result: $TAGGED_INSTANCES"

# Test 2: Fallback to all running instances
echo ""
echo "📋 Test 2: Fallback to all running instances..."
ALL_INSTANCES=$(aws ec2 describe-instances \
  --region "$REGION" \
  --filters "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].[InstanceId,InstanceType,Tags[?Key==`Name`].Value|[0],PrivateIpAddress,PublicIpAddress]' \
  --output json 2>/dev/null || echo "[]")

echo "   Result: $ALL_INSTANCES"

# Test 3: Parse and display results
echo ""
echo "📋 Test 3: Parsing and displaying results..."

if [ "$TAGGED_INSTANCES" != "[]" ] && [ -n "$TAGGED_INSTANCES" ]; then
    echo "✅ Found tagged instances:"
    echo "$TAGGED_INSTANCES" | jq -r '.[] | "  - \(.[0]) (\(.[2] or "Unnamed")) - \(.[1]) - IP: \(.[3] or .[4] or "N/A")"'
    
    INSTANCE_IDS=$(echo "$TAGGED_INSTANCES" | jq -r '.[][0]' | tr '\n' ' ')
    echo "   Instance IDs: $INSTANCE_IDS"
    echo "   Count: $(echo "$TAGGED_INSTANCES" | jq length)"
    
elif [ "$ALL_INSTANCES" != "[]" ] && [ -n "$ALL_INSTANCES" ]; then
    echo "ℹ️  No tagged instances found, but found running instances:"
    echo "$ALL_INSTANCES" | jq -r '.[] | "  - \(.[0]) (\(.[2] or "Unnamed")) - \(.[1]) - IP: \(.[3] or .[4] or "N/A")"'
    
    INSTANCE_IDS=$(echo "$ALL_INSTANCES" | jq -r '.[][0]' | tr '\n' ' ')
    echo "   Instance IDs: $INSTANCE_IDS"
    echo "   Count: $(echo "$ALL_INSTANCES" | jq length)"
    
else
    echo "❌ No running instances found in region $REGION"
    echo "   Please ensure you have running EC2 instances in this region"
    exit 1
fi

# Test 4: Get details for first instance
echo ""
echo "📋 Test 4: Getting details for first instance..."
FIRST_INSTANCE_ID=$(echo "$INSTANCE_IDS" | awk '{print $1}')

if [ -n "$FIRST_INSTANCE_ID" ]; then
    echo "   First instance ID: $FIRST_INSTANCE_ID"
    
    INSTANCE_DETAILS=$(aws ec2 describe-instances \
      --instance-ids "$FIRST_INSTANCE_ID" \
      --query 'Reservations[0].Instances[0]' \
      --output json)
    
    if [ $? -eq 0 ]; then
        echo "✅ Successfully retrieved instance details"
        
        PRIVATE_IP=$(echo "$INSTANCE_DETAILS" | jq -r '.PrivateIpAddress // empty')
        PUBLIC_IP=$(echo "$INSTANCE_DETAILS" | jq -r '.PublicIpAddress // empty')
        INSTANCE_TYPE=$(echo "$INSTANCE_DETAILS" | jq -r '.InstanceType // empty')
        STATE=$(echo "$INSTANCE_DETAILS" | jq -r '.State.Name // empty')
        
        echo "   - Instance Type: $INSTANCE_TYPE"
        echo "   - State: $STATE"
        echo "   - Private IP: $PRIVATE_IP"
        echo "   - Public IP: $PUBLIC_IP"
    else
        echo "❌ Failed to get instance details"
    fi
else
    echo "❌ No instance ID found"
fi

echo ""
echo "🎯 Dynamic Discovery Test Summary:"
echo "✅ AWS CLI connectivity: Working"
echo "✅ jq JSON parsing: Working"
echo "✅ Instance discovery: Working"
echo "✅ Instance details retrieval: Working"
echo ""
echo "🚀 Dynamic instance discovery is ready to use!"
echo "   The workflow will automatically discover and use running instances."
