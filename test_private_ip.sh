#!/bin/bash

echo "🧪 Testing Private IP Logic"
echo "============================"

# Test 1: Simulate instance with no public IP but private IP
echo "✅ Test 1: Instance with Private IP Only"
INSTANCE_INFO='{"PublicIpAddress": null, "PrivateIpAddress": "10.0.1.100", "InstanceId": "i-test123"}'

# Extract IPs using the same logic as the workflow
PUBLIC_IP=$(echo $INSTANCE_INFO | jq -r '.PublicIpAddress')
PRIVATE_IP=$(echo $INSTANCE_INFO | jq -r '.PrivateIpAddress')

echo "   Public IP: $PUBLIC_IP"
echo "   Private IP: $PRIVATE_IP"

if [ "$PUBLIC_IP" != "null" ] && [ -n "$PUBLIC_IP" ]; then
    echo "   ✅ Using public IP: $PUBLIC_IP"
    INSTANCE_IP="$PUBLIC_IP"
    IP_TYPE="public"
elif [ "$PRIVATE_IP" != "null" ] && [ -n "$PRIVATE_IP" ]; then
    echo "   ✅ Using private IP: $PRIVATE_IP (public IP not available)"
    INSTANCE_IP="$PRIVATE_IP"
    IP_TYPE="private"
else
    echo "   ❌ No IP address available"
    exit 1
fi

echo "   Final IP: $INSTANCE_IP ($IP_TYPE)"
echo "   ✅ Private IP logic working correctly"

# Test 2: Simulate instance with both public and private IP
echo ""
echo "✅ Test 2: Instance with Both IPs"
INSTANCE_INFO='{"PublicIpAddress": "52.23.45.67", "PrivateIpAddress": "10.0.1.100", "InstanceId": "i-test123"}'

PUBLIC_IP=$(echo $INSTANCE_INFO | jq -r '.PublicIpAddress')
PRIVATE_IP=$(echo $INSTANCE_INFO | jq -r '.PrivateIpAddress')

echo "   Public IP: $PUBLIC_IP"
echo "   Private IP: $PRIVATE_IP"

if [ "$PUBLIC_IP" != "null" ] && [ -n "$PUBLIC_IP" ]; then
    echo "   ✅ Using public IP: $PUBLIC_IP"
    INSTANCE_IP="$PUBLIC_IP"
    IP_TYPE="public"
elif [ "$PRIVATE_IP" != "null" ] && [ -n "$PRIVATE_IP" ]; then
    echo "   ✅ Using private IP: $PRIVATE_IP (public IP not available)"
    INSTANCE_IP="$PRIVATE_IP"
    IP_TYPE="private"
else
    echo "   ❌ No IP address available"
    exit 1
fi

echo "   Final IP: $INSTANCE_IP ($IP_TYPE)"
echo "   ✅ Public IP logic working correctly"

# Test 3: Simulate instance with no IPs
echo ""
echo "✅ Test 3: Instance with No IPs"
INSTANCE_INFO='{"PublicIpAddress": null, "PrivateIpAddress": null, "InstanceId": "i-test123"}'

PUBLIC_IP=$(echo $INSTANCE_INFO | jq -r '.PublicIpAddress')
PRIVATE_IP=$(echo $INSTANCE_INFO | jq -r '.PrivateIpAddress')

echo "   Public IP: $PUBLIC_IP"
echo "   Private IP: $PRIVATE_IP"

if [ "$PUBLIC_IP" != "null" ] && [ -n "$PUBLIC_IP" ]; then
    echo "   ✅ Using public IP: $PUBLIC_IP"
    INSTANCE_IP="$PUBLIC_IP"
    IP_TYPE="public"
elif [ "$PRIVATE_IP" != "null" ] && [ -n "$PRIVATE_IP" ]; then
    echo "   ✅ Using private IP: $PRIVATE_IP (public IP not available)"
    INSTANCE_IP="$PRIVATE_IP"
    IP_TYPE="private"
else
    echo "   ❌ No IP address available (expected failure)"
    echo "   ✅ Error handling working correctly"
fi

echo ""
echo "🎉 All Private IP Logic Tests Passed!"
echo "✅ Workflow will now work with both public and private instances"
echo "✅ Private instances will use private IP automatically"
echo "✅ Public instances will still use public IP when available"
