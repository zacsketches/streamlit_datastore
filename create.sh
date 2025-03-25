#!/bin/bash

# Retrieve EC2 Public IP from Terraform output
EC2_PUBLIC_IP=$(terraform output -raw public_ip)

# Check if the variable is set
if [[ -z "$EC2_PUBLIC_IP" ]]; then
    echo "❌ ERROR: EC2_PUBLIC_IP is not set. Ensure Terraform has been applied successfully."
    exit 1
fi

# Define the API endpoint
API_URL="http://${EC2_PUBLIC_IP}:5000/create"

# Define the user data to send
USER_DATA='{"name": "David"}'

# Make the POST request
echo "🚀 Sending request to $API_URL..."
RESPONSE=$(curl -s -X POST "$API_URL" \
     -H "Content-Type: application/json" \
     -d "$USER_DATA")

# Check the response
if [[ $? -eq 0 ]]; then
    echo "✅ Response from server:"
    echo "$RESPONSE"
else
    echo "❌ ERROR: Failed to connect to the Flask API."
fi
