#!/bin/sh

# Set the AWS region
AWS_REGION="eu-central-1"

# Set the S3 bucket name
S3_BUCKET="686255952373-eliza-agents"

# List all objects in the S3 bucket recursively
aws s3 ls s3://${S3_BUCKET}/ --recursive --region ${AWS_REGION}
