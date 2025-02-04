#!env python
import os
import json
import boto3
from datetime import datetime

AWS_REGION = os.environ.get("AWS_REGION", "eu-central-1")
AMI_ID = os.environ.get("AMI_ID", "")
INSTANCE_TYPE = os.environ.get("INSTANCE_TYPE", "t3.micro")
SUBNET_ID = os.environ.get("SUBNET_ID", "")
SECURITY_GROUP_ID = os.environ.get("SECURITY_GROUP_ID", "")
# Environment variable AMI_OWNER defines the owner (e.g., "self" or an AWS account id)
AMI_OWNER = os.environ.get("AMI_OWNER", "self")
# AMI_TAG_FILTERS is a JSON object like: {"Name": "eliza-base", "Environment": "prod"}
AMI_TAG_FILTERS = os.environ.get(
    "AMI_TAG_FILTERS", '{"Name": "eliza-base", "Environment": "prod"}'
)

USER_DATA = """#!/bin/bash
echo "Custom Eliza instance bootstrapping here..."
"""


def get_latest_ami(ec2, owner, tag_filters):
    """
    Returns the ImageId of the latest AMI matching the provided owner and tag filters.
    tag_filters should be a dict (e.g., {"Name": "eliza-base", "Environment": "prod"})
    """
    filters = []
    for k, v in tag_filters.items():
        filters.append({"Name": f"tag:{k}", "Values": [v]})
    response = ec2.describe_images(Owners=[owner], Filters=filters)
    images = response.get("Images", [])
    if not images:
        return None
    # Sort images by CreationDate descending (most recent first)
    images.sort(key=lambda x: x["CreationDate"], reverse=True)
    return images[0]["ImageId"]


def lambda_handler(event, context):
    """
    Launches a new EC2 instance using configuration from the event,
    falling back to default environment variables.
    """
    # Load configuration from event or use defaults
    aws_region = event.get("AWS_REGION", AWS_REGION)
    ami_id = event.get("AMI_ID", AMI_ID)
    instance_type = event.get("INSTANCE_TYPE", INSTANCE_TYPE)
    subnet_id = event.get("SUBNET_ID", SUBNET_ID)
    security_group_id = event.get("SECURITY_GROUP_ID", SECURITY_GROUP_ID)
    ami_owner = event.get("AMI_OWNER", AMI_OWNER)
    ami_tag_filters = event.get("AMI_TAG_FILTERS", AMI_TAG_FILTERS)
    user_data = event.get("USER_DATA", USER_DATA)

    # Convert ami_tag_filters from JSON string to dict (if needed)
    try:
        tag_filters = (
            json.loads(ami_tag_filters)
            if isinstance(ami_tag_filters, str)
            else ami_tag_filters
        )
    except Exception:
        tag_filters = {}

    ec2 = boto3.client("ec2", region_name=aws_region)

    # If AMI_ID is not provided, look up the latest AMI based on owner & tag filters.
    ami_to_use = ami_id or get_latest_ami(ec2, ami_owner, tag_filters)
    if not ami_to_use:
        return {
            "statusCode": 500,
            "body": json.dumps(
                {"error": "No valid AMI found with the provided filters."}
            ),
        }

    try:
        response = ec2.run_instances(
            ImageId=ami_to_use,
            InstanceType=instance_type,
            MinCount=1,
            MaxCount=1,
            SubnetId=subnet_id,
            SecurityGroupIds=[security_group_id] if security_group_id else [],
            UserData=user_data,
            TagSpecifications=[
                {
                    "ResourceType": "instance",
                    "Tags": [
                        {
                            "Key": "Name",
                            "Value": event.get("InstanceName", "eliza-instance"),
                        },
                        {
                            "Key": "Environment",
                            "Value": event.get("Environment", "prod"),
                        },
                    ],
                }
            ],
        )
        instance_id = response["Instances"][0]["InstanceId"]
        return {
            "statusCode": 200,
            "body": json.dumps(
                {"message": "Instance launched", "instance_id": instance_id}
            ),
        }
    except Exception as e:
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}


if __name__ == "__main__":
    lambda_handler(None, None)
