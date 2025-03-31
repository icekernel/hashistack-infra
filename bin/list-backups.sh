#!/bin/sh

# Set the AWS region
AWS_REGION="sa-east-1"

# Set the S3 bucket name
S3_BUCKET="711054401116-eliza-agents"

# List all objects in the S3 bucket recursively
aws s3 ls s3://${S3_BUCKET}/ --recursive --region ${AWS_REGION}
