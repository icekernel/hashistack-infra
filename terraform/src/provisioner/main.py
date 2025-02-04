#!env python
import os
import json
import boto3

CUSTOMER = os.environ.get("CUSTOMER_ID", "ABC123XYZ42")
AWS_REGION = os.environ.get("AWS_REGION", "eu-central-1")
AMI_ID = os.environ.get("AMI_ID", "")
INSTANCE_TYPE = os.environ.get("INSTANCE_TYPE", "t3.small")
SUBNET_ID = os.environ.get("SUBNET_ID", "")
# Environment variable AMI_OWNER defines the owner (e.g., "self" or an AWS account id)
AMI_OWNER = os.environ.get("AMI_OWNER", "686255952373")
ENVIRONMENT = os.environ.get("ENVIRONMENT", "prod1")
ROLE = os.environ.get("ROLE", "eliza")
AMI_TAG_FILTERS = os.environ.get(
    "AMI_TAG_FILTERS", '{"Name": f"{ENVIRONMENT}-{ROLE}-*"}'
)
# SECURITY_GROUP_ID if provided will be used as comma separated list of ids;
# if not provided, we will look up security groups by names: {ENVIRONMENT}-nomad, -consul, -{ROLE}.
SECURITY_GROUP_ID = os.environ.get("SECURITY_GROUP_ID", "")

USER_DATA = """#cloud-config

runcmd:
  - sudo -u ubuntu /home/ubuntu/ansible-pull.sh
"""


def get_latest_ami(ec2, owner, tag_filters):
    """
    Returns the ImageId of the latest AMI matching the provided owner and tag filters.
    tag_filters should be a dict (e.g., {"Role": "eliza", "Environment": "prod1"})
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


def lookup_security_group_ids(ec2, environment, role):
    group_names = [
        f"{environment}-nomad",
        f"{environment}-consul",
        f"{environment}-{role}",
    ]
    response = ec2.describe_security_groups(
        Filters=[{"Name": "group-name", "Values": group_names}]
    )
    groups = response.get("SecurityGroups", [])
    # Return just the security group ids
    return [group["GroupId"] for group in groups]


def lookup_vpc_id(ec2, environment):
    vpc_name = f"prism1-{environment}"
    response = ec2.describe_vpcs(Filters=[{"Name": "tag:Name", "Values": [vpc_name]}])
    vpcs = response.get("Vpcs", [])
    if not vpcs:
        raise Exception(f"No VPC found with name {vpc_name}")
    return vpcs[0]["VpcId"]


def lookup_private_subnets(ec2, vpc_id, environment):
    response = ec2.describe_subnets(
        Filters=[
            {"Name": "vpc-id", "Values": [vpc_id]},
            {"Name": "tag:Name", "Values": [f"prism1-{environment}-private*"]},
        ]
    )
    subnets = response.get("Subnets", [])
    if not subnets:
        raise Exception(
            f"No private subnets found in VPC {vpc_id} with name prism1-{environment}-private*"
        )
    return subnets


def lambda_handler(event, context):
    """
    Launches a new EC2 instance using configuration from the event,
    falling back to default environment variables.
    """
    environment = event.get("ENVIRONMENT", ENVIRONMENT)
    role = event.get("ROLE", ROLE)
    aws_region = event.get("AWS_REGION", AWS_REGION)
    ami_id = event.get("AMI_ID", AMI_ID)
    instance_type = event.get("INSTANCE_TYPE", INSTANCE_TYPE)
    subnet_id = event.get("SUBNET_ID", "")  # might be empty
    ami_owner = event.get("AMI_OWNER", AMI_OWNER)
    ami_tag_filters = event.get("AMI_TAG_FILTERS", AMI_TAG_FILTERS)
    user_data = event.get("USER_DATA", USER_DATA)
    customer = event.get("CUSTOMER_ID", CUSTOMER)

    # Determine instance name based on the environment override.
    instance_name = event.get("InstanceName", f"{environment}-{role}-{customer}")

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

    # Use provided AMI or look it up
    ami_to_use = ami_id or get_latest_ami(ec2, ami_owner, tag_filters)
    if not ami_to_use:
        return {
            "statusCode": 500,
            "body": json.dumps(
                {"error": "No valid AMI found with the provided filters."}
            ),
        }

    # If subnet_id is not provided, look up the VPC and then its private subnets based on name.
    if not subnet_id:
        try:
            vpc_id = lookup_vpc_id(ec2, environment)
            private_subnets = lookup_private_subnets(ec2, vpc_id, environment)
            subnet_id = private_subnets[0]["SubnetId"]
        except Exception as e:
            return {"statusCode": 500, "body": json.dumps({"error": str(e)})}

    # Lookup security group ids (either provided or via lookup)
    if SECURITY_GROUP_ID:
        security_group_ids = SECURITY_GROUP_ID.split(",")
    else:
        security_group_ids = lookup_security_group_ids(ec2, environment, role)

    try:
        response = ec2.run_instances(
            ImageId=ami_to_use,
            InstanceType=instance_type,
            MinCount=1,
            MaxCount=1,
            UserData=user_data,
            IamInstanceProfile={
                "Arn": f"arn:aws:iam::{ami_owner}:instance-profile/{environment}-{role}"
            },
            BlockDeviceMappings=[
                {
                    "DeviceName": "/dev/sda1",  # adjust based on your AMI device mapping
                    "Ebs": {
                        "VolumeSize": 52,
                        "VolumeType": "gp2",
                        "DeleteOnTermination": True,
                    },
                }
            ],
            NetworkInterfaces=[
                {
                    "DeviceIndex": 0,
                    "SubnetId": subnet_id,
                    "Groups": security_group_ids,
                    "AssociatePublicIpAddress": False,
                    "DeleteOnTermination": True,
                }
            ],
            MetadataOptions={
                "HttpTokens": "required",
                "HttpEndpoint": "enabled",
                "InstanceMetadataTags": "enabled",
            },
            TagSpecifications=[
                {
                    "ResourceType": "instance",
                    "Tags": [
                        {"Key": "Name", "Value": instance_name},
                        {"Key": "Environment", "Value": environment},
                        {"Key": "Role", "Value": role},
                        {"Key": "Customer", "Value": customer},
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
    print(lambda_handler({}, {}))
