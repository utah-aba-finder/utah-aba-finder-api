#!/bin/bash

# Setup script for AWS S3 logo storage
echo "Setting up AWS S3 for logo storage..."

# Set AWS environment variables
# Replace these with your actual AWS credentials
export AWS_ACCESS_KEY_ID="YOUR_AWS_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="YOUR_AWS_SECRET_ACCESS_KEY"
export AWS_REGION="us-west-2"

echo "AWS credentials set for logo storage"
echo "S3 Bucket: utahabalogos"
echo "Region: us-west-2"

# Test S3 connection
echo "Testing S3 connection..."
aws s3 ls s3://utahabalogos/ --region us-west-2 | head -5

echo "Setup complete! Make sure to set these environment variables in your production environment:"
echo "AWS_ACCESS_KEY_ID=YOUR_AWS_ACCESS_KEY_ID"
echo "AWS_SECRET_ACCESS_KEY=YOUR_AWS_SECRET_ACCESS_KEY"
echo "AWS_REGION=us-west-2"
