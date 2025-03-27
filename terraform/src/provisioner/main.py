#!env python
import os
import json
import boto3
import logging
import time
import random
import string
import requests

LOG = logging.getLogger(__name__)
LOG.setLevel(logging.INFO)

AWS_REGION = os.environ.get("AWS_REGION", "eu-central-1")
AWS_ACCOUNT = os.environ.get("AMI_OWNER", "686255952373")
ENVIRONMENT = os.environ.get("ENVIRONMENT", "test1")
ROLE = os.environ.get("ROLE", "eliza")
AMI_TAG_FILTERS = os.environ.get(
    "AMI_TAG_FILTERS", '{"Name": f"{ENVIRONMENT}-{ROLE}-*"}'
)

USER_DATA = ""


def get_latest_ami(ec2, owner, tag_filters):
    """
    Returns the ImageId of the latest AMI matching the provided owner and tag filters.
    tag_filters should be a dict (e.g., {"Role": "eliza", "Environment": "test1"})
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
        f"{environment}-endpoint",
    ]
    response = ec2.describe_security_groups(
        Filters=[{"Name": "group-name", "Values": group_names}]
    )
    groups = response.get("SecurityGroups", [])
    # Return just the security group ids
    return [group["GroupId"] for group in groups]


def lookup_vpc_id(ec2, product_id, environment):
    vpc_name = f"{product_id}-{environment}"
    response = ec2.describe_vpcs(Filters=[{"Name": "tag:Name", "Values": [vpc_name]}])
    vpcs = response.get("Vpcs", [])
    if not vpcs:
        raise Exception(f"No VPC found with name {vpc_name}")
    return vpcs[0]["VpcId"]


def lookup_private_subnets(ec2, vpc_id, product_id, environment):
    response = ec2.describe_subnets(
        Filters=[
            {"Name": "vpc-id", "Values": [vpc_id]},
            {"Name": "tag:Name", "Values": [f"{product_id}-{environment}-private*"]},
        ]
    )
    subnets = response.get("Subnets", [])
    if not subnets:
        raise Exception(
            f"No private subnets found in VPC {vpc_id} with name {product_id}-{environment}-private*"
        )
    return subnets


def create_eliza_secret(sm_client, environment, role, customer_id, config_data):
    secret_name = f"{environment}-{role}-{customer_id}"
    try:
        secret_description = sm_client.describe_secret(SecretId=secret_name)
        if secret_description.get("DeletedDate"):
            LOG.info("Secret %s is marked for deletion. Restoring it.", secret_name)
            sm_client.restore_secret(SecretId=secret_name)
            # Wait a short time to ensure the restore is processed
            time.sleep(5)
        sm_client.put_secret_value(SecretId=secret_name, SecretString=config_data)
        LOG.info("Updated secret %s", secret_name)
    except sm_client.exceptions.ResourceNotFoundException:
        sm_client.create_secret(Name=secret_name, SecretString=config_data)
        LOG.info("Created secret %s", secret_name)
    return secret_name


def create_instance_profile(iam_client, environment, role, customer_id, secret_name):
    role_name = f"{environment}-{role}-{customer_id}"
    assume_role_policy = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {"Service": "ec2.amazonaws.com"},
                "Action": "sts:AssumeRole",
            }
        ],
    }
    try:
        iam_client.get_role(RoleName=role_name)
        LOG.info("IAM Role %s already exists", role_name)
    except iam_client.exceptions.NoSuchEntityException:
        iam_client.create_role(
            RoleName=role_name,
            AssumeRolePolicyDocument=json.dumps(assume_role_policy),
            Description="Role for EC2 instance to access eliza secret, SSM and CloudWatch",
        )
        LOG.info("Created IAM Role %s", role_name)

    # Combined inline policy to cover secrets access (if needed), ec2 DescribeInstances and SSM update.
    policy_document = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": ["secretsmanager:GetSecretValue"],
                "Resource": f"arn:aws:secretsmanager:{AWS_REGION}:{AWS_ACCOUNT}:secret:{secret_name}*",
            },
            {"Effect": "Allow", "Action": ["ec2:DescribeInstances"], "Resource": "*"},
            {
                "Effect": "Allow",
                "Action": ["ssm:UpdateInstanceInformation"],
                "Resource": "*",
            },
            {
                "Effect": "Allow",
                "Action": ["cloudwatch:PutMetricData"],
                "Resource": "*",
            },
            {
                "Sid": "ElizaAgentsFolderAccess",
                "Effect": "Allow",
                "Action": [
                    "s3:*",
                ],
                "Resource": [
                    f"arn:aws:s3:::{AWS_ACCOUNT}-eliza-agents/{role_name}",
                    f"arn:aws:s3:::{AWS_ACCOUNT}-eliza-agents/{role_name}/*",
                ],
            },
            {
                "Sid": "ElizaAgentsBucketAccess",
                "Effect": "Allow",
                "Action": ["s3:GetBucketLocation", "s3:ListBucket"],
                "Resource": [
                    f"arn:aws:s3:::{AWS_ACCOUNT}-eliza-agents",
                    f"arn:aws:s3:::{AWS_ACCOUNT}-eliza-agents/*",
                ],
            },
            {
                "Effect": "Allow",
                "Action": ["secretsmanager:GetSecretValue"],
                "Resource": [
                    f"arn:aws:secretsmanager:{AWS_REGION}:{AWS_ACCOUNT}:secret:/{environment}/consul/node_registration*",
                    f"arn:aws:secretsmanager:{AWS_REGION}:{AWS_ACCOUNT}:secret:/{environment}/consul/nomad_agents*",
                    f"arn:aws:secretsmanager:{AWS_REGION}:{AWS_ACCOUNT}:secret:/{environment}/nomad/client_token*",
                ],
            },
        ],
    }
    iam_client.put_role_policy(
        RoleName=role_name,
        PolicyName="eliza-instance-profile-inline",
        PolicyDocument=json.dumps(policy_document),
    )
    LOG.info("Added inline policy to role %s", role_name)

    # Attach managed policies for SSM and CloudWatch Agent
    managed_policy_arns = [
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
        "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    ]
    for policy_arn in managed_policy_arns:
        try:
            iam_client.attach_role_policy(RoleName=role_name, PolicyArn=policy_arn)
        except Exception as e:
            LOG.error(
                "Error attaching policy %s to role %s: %s",
                policy_arn,
                role_name,
                str(e),
            )

    created_profile = False
    try:
        iam_client.get_instance_profile(InstanceProfileName=role_name)
    except iam_client.exceptions.NoSuchEntityException:
        iam_client.create_instance_profile(InstanceProfileName=role_name)
        created_profile = True

    # Attach role if newly created
    if created_profile:
        try:
            iam_client.add_role_to_instance_profile(
                InstanceProfileName=role_name, RoleName=role_name
            )
        except iam_client.exceptions.LimitExceededException:
            pass

    # Retrieve and return the ARN for run_instances
    resp = iam_client.get_instance_profile(InstanceProfileName=role_name)
    profile_arn = resp["InstanceProfile"]["Arn"]
    return profile_arn


def register_service_with_consul(
    instance_id, environment, role, customer_id, consul_token
):
    """Registers the Eliza service with Consul on the given instance."""
    ec2 = boto3.client("ec2")
    try:
        response = ec2.describe_instances(InstanceIds=[instance_id])
        instance = response["Reservations"][0]["Instances"][0]
        private_ip = instance["PrivateIpAddress"]
        tags = instance.get("Tags", [])
        consul_server_tag = next(
            (tag for tag in tags if tag["Key"] == "ConsulServer"), None
        )

        if not consul_server_tag or consul_server_tag["Value"] != environment:
            LOG.warning(
                "Instance %s is not a Consul server for environment %s. Skipping registration.",
                instance_id,
                environment,
            )
            return

        consul_host = private_ip  # Consul server runs on the same instance
        consul_port = 8500  # Default Consul port

        service_name = f"eliza-{instance_id}"
        service_port = 3000  # Default Eliza port, make sure this is correct
        health_check_interval = "10s"
        health_check_timeout = "5s"

        registration_payload = {
            "ID": service_name,
            "Name": "eliza",
            "Tags": [
                f"environment={environment}",
                f"role={role}",
                f"customer_id={customer_id}",
            ],
            "Address": private_ip,
            "Port": service_port,
            "Check": {
                "DeregisterCriticalServiceAfter": "30m",
                "Interval": health_check_interval,
                "Timeout": health_check_timeout,
                "HTTP": f"http://{private_ip}:{service_port}/healthcheck",
            },
        }

        headers = {"Content-Type": "application/json"}
        if consul_token:
            headers["X-Consul-Token"] = consul_token

        consul_url = f"http://{consul_host}:{consul_port}/v1/agent/service/register"
        response = requests.put(
            consul_url, data=json.dumps(registration_payload), headers=headers
        )

        if response.status_code == 200:
            LOG.info(
                "Successfully registered service %s with Consul on %s",
                service_name,
                consul_host,
            )
        else:
            LOG.error(
                "Failed to register service %s with Consul on %s. Status code: %s, Response: %s",
                service_name,
                consul_host,
                response.status_code,
                response.text,
            )

    except Exception as e:
        LOG.error(
            "Error registering service with Consul for instance %s: %s", instance_id, e
        )


def create_customer_resources(payload):

    # Retrieve parameters
    environment = payload.get("ENVIRONMENT", os.environ.get("ENVIRONMENT", "test1"))
    role = payload.get("ROLE", os.environ.get("ROLE", "eliza"))
    aws_region = payload.get("AWS_REGION", os.environ.get("AWS_REGION", "eu-central-1"))
    ami_id = payload.get("AMI_ID", os.environ.get("AMI_ID", ""))
    instance_type = payload.get(
        "INSTANCE_TYPE", os.environ.get("INSTANCE_TYPE", "c5.2xlarge")
    )
    subnet_id = payload.get("SUBNET_ID", "")
    ami_owner = payload.get("AMI_OWNER", os.environ.get("AMI_OWNER", "686255952373"))
    ami_tag_filters = payload.get(
        "AMI_TAG_FILTERS",
        os.environ.get("AMI_TAG_FILTERS", '{"Name": "test1-eliza-*"}'),
    )
    user_data = payload.get("USER_DATA", "")

    eliza_config = payload.get("eliza_config", None)
    if not eliza_config:
        return {"statusCode": 400, "body": "Missing eliza_config in event payload"}

    # Extract meta data
    customer_id = eliza_config.get("meta", {}).get("customerId", None)
    if not customer_id:
        return {"statusCode": 400, "body": "Missing customerId in eliza_config"}
    github_repo_url = eliza_config.get("meta", {}).get("githubRepoUrl", None)
    if not github_repo_url:
        return {"statusCode": 400, "body": "Missing GitHubRepoUrl in eliza_config"}
    checkout_revision = eliza_config.get("meta", {}).get("checkoutRevision", None)
    if not checkout_revision:
        return {"statusCode": 400, "body": "Missing CheckoutRevision in eliza_config"}

    # Create or update secret
    sm_client = boto3.client("secretsmanager")
    secret_name = create_eliza_secret(
        sm_client, environment, role, customer_id, json.dumps(eliza_config)
    )

    # Create instance profile
    iam_client = boto3.client("iam")
    profile_arn = create_instance_profile(
        iam_client, environment, role, customer_id, secret_name
    )

    try:
        tag_filters = (
            json.loads(ami_tag_filters)
            if isinstance(ami_tag_filters, str)
            else ami_tag_filters
        )
    except Exception:
        tag_filters = {}

    ec2 = boto3.client("ec2", region_name=aws_region)
    ami_to_use = ami_id or get_latest_ami(ec2, ami_owner, tag_filters)
    if not ami_to_use:
        return {"statusCode": 500, "body": json.dumps({"error": "No valid AMI found."})}

    # VPC/subnet/SG lookups
    product_id = payload.get("PRODUCT_ID", os.environ.get("PRODUCT_ID", "prism1"))
    if not subnet_id:
        vpc_id = lookup_vpc_id(ec2, product_id, environment)
        private_subnets = lookup_private_subnets(ec2, vpc_id, product_id, environment)
        subnet_id = private_subnets[0]["SubnetId"]

    sec_id = os.environ.get("SECURITY_GROUP_ID", "")
    if sec_id:
        security_group_ids = sec_id.split(",")
    else:
        security_group_ids = lookup_security_group_ids(ec2, environment, role)

    instance_name = payload.get("InstanceName", f"{environment}-{role}-{customer_id}")

    # Launch instance with retry logic
    max_retries = 5
    for attempt in range(1, max_retries + 1):
        try:
            response = ec2.run_instances(
                ImageId=ami_to_use,
                InstanceType=instance_type,
                MinCount=1,
                MaxCount=1,
                UserData=user_data,
                IamInstanceProfile={"Arn": profile_arn},
                BlockDeviceMappings=[
                    {
                        "DeviceName": "/dev/sda1",
                        "Ebs": {
                            "VolumeSize": 100,
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
                    "HttpPutResponseHopLimit": 2,
                },
                TagSpecifications=[
                    {
                        "ResourceType": "instance",
                        "Tags": [
                            {"Key": "Name", "Value": instance_name},
                            {"Key": "Environment", "Value": environment},
                            {"Key": "Role", "Value": role},
                            {"Key": "CustomerId", "Value": customer_id},
                            {"Key": "GitHubRepoUrl", "Value": github_repo_url},
                            {"Key": "CheckoutRevision", "Value": checkout_revision},
                        ],
                    }
                ],
            )
            instance_id = response["Instances"][0]["InstanceId"]

            # Retrieve Consul token from Secrets Manager
            # sm_client = boto3.client("secretsmanager")
            # try:
            #     consul_token_secret = sm_client.get_secret_value(
            #         SecretId=f"{environment}/consul/node_registration"
            #     )
            #     consul_token = consul_token_secret["SecretString"]
            # except sm_client.exceptions.ResourceNotFoundException:
            #     LOG.warning(
            #         "Consul token secret not found. Service registration will proceed without token."
            #     )
            #     consul_token = None

            # # Register service with Consul
            # register_service_with_consul(
            #     instance_id, environment, role, customer_id, consul_token
            # )

            LOG.info("Instance %s launched successfully", instance_id)
            break
        except Exception as e:
            LOG.info("Attempt %d: Error launching instance: %s", attempt, str(e))
            if attempt == max_retries:
                return {"statusCode": 500, "body": json.dumps({"error": str(e)})}
            time.sleep(5)

    return {
        "statusCode": 200,
        "body": json.dumps(
            {"message": "Instance launched", "instance_id": instance_id}
        ),
    }


def update_customer_resources(payload):
    # Extract relevant data from the event
    try:
        environment = payload.get("ENVIRONMENT", os.environ.get("ENVIRONMENT", "test1"))
        role = payload.get("ROLE", os.environ.get("ROLE", "eliza"))
        eliza_config = payload.get("eliza_config", None)
        if not eliza_config:
            return {"statusCode": 400, "body": "Missing eliza_config in event payload"}

        # Extract meta data
        customer_id = eliza_config.get("meta", {}).get("customerId", None)
    except (KeyError, json.JSONDecodeError) as e:
        return {
            "statusCode": 400,
            "body": json.dumps(f"Error: Missing or invalid event data: {str(e)}"),
        }

    # Find the instance ID based on the customer ID
    ec2_client = boto3.client("ec2")
    try:
        response = ec2_client.describe_instances(
            Filters=[
                {"Name": "tag:CustomerId", "Values": [customer_id]},
                {"Name": "tag:Environment", "Values": [environment]},
                {"Name": "tag:Role", "Values": [role]},
            ]
        )
        instances = [
            instance
            for reservation in response["Reservations"]
            for instance in reservation["Instances"]
        ]
        if not instances:
            return {
                "statusCode": 404,
                "body": json.dumps(
                    f"Error: No instance found with customerId {customer_id}"
                ),
            }
        instance_id = instances[0]["InstanceId"]
    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps(f"Error describing instances: {str(e)}"),
        }

    # Construct the SSM command
    ssm_client = boto3.client("ssm")
    try:
        response = ssm_client.send_command(
            InstanceIds=[instance_id],
            DocumentName="AWS-RunShellScript",
            Parameters={
                "commands": ["sudo -u ubuntu /opt/actions/eliza-reconfigure-pull.sh"]
            },
        )
        command_id = response["Command"]["CommandId"]
        return {
            "statusCode": 200,
            "body": json.dumps(
                f"Successfully triggered Eliza Reconfigure Pull on {instance_id} with command ID: {command_id}"
            ),
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps(f"Error triggering Eliza Reconfigure Pull: {str(e)}"),
        }


def destroy_customer_resources(payload):
    # Pick required variables from event or environment
    environment = payload.get("ENVIRONMENT", os.environ.get("ENVIRONMENT", "test1"))
    role = payload.get("ROLE", os.environ.get("ROLE", "eliza"))
    eliza_config = payload.get("eliza_config", {})
    meta = eliza_config.get("meta", {})
    customer_id = meta.get("customerId", None)
    if not customer_id:
        return {"statusCode": 400, "meta": "Missing customerId"}

    # Assume secret name was created as follows
    secret_name = f"{environment}-{role}-{customer_id}"
    LOG.info("Scheduling deletion of secret %s", secret_name)
    sm_client = boto3.client("secretsmanager")
    try:
        sm_client.delete_secret(SecretId=secret_name, RecoveryWindowInDays=7)
    except Exception as e:
        LOG.error("Error scheduling secret deletion: %s", str(e))

    # Delete IAM role and instance profile
    iam_client = boto3.client("iam")
    role_name = f"{environment}-{role}-{customer_id}"
    LOG.info("Deleting IAM resources for role %s", role_name)
    try:
        # Detach managed policies
        attached = iam_client.list_attached_role_policies(RoleName=role_name)
        for policy in attached.get("AttachedPolicies", []):
            iam_client.detach_role_policy(
                RoleName=role_name, PolicyArn=policy["PolicyArn"]
            )
    except Exception as e:
        LOG.error(
            "Error detaching managed policies from role %s: %s", role_name, str(e)
        )
    try:
        # Delete inline policies
        inline = iam_client.list_role_policies(RoleName=role_name)
        for policy_name_key in inline.get("PolicyNames", []):
            iam_client.delete_role_policy(
                RoleName=role_name, PolicyName=policy_name_key
            )
    except Exception as e:
        LOG.error("Error deleting inline policies from role %s: %s", role_name, str(e))
    try:
        # Remove role from instance profile if attached
        profile = iam_client.get_instance_profile(InstanceProfileName=role_name)
        for r in profile["InstanceProfile"].get("Roles", []):
            iam_client.remove_role_from_instance_profile(
                InstanceProfileName=role_name, RoleName=r["RoleName"]
            )
    except Exception as e:
        LOG.error("Error removing role from instance profile %s: %s", role_name, str(e))
    try:
        # Delete the instance profile
        iam_client.delete_instance_profile(InstanceProfileName=role_name)
    except Exception as e:
        LOG.error("Error deleting instance profile %s: %s", role_name, str(e))
    try:
        # Delete the IAM role
        iam_client.delete_role(RoleName=role_name)
    except Exception as e:
        LOG.error("Error deleting IAM role %s: %s", role_name, str(e))

    # Terminate EC2 instance(s) associated with the customer
    ec2 = boto3.client("ec2", region_name=os.environ.get("AWS_REGION", "eu-central-1"))
    try:
        reservations = ec2.describe_instances(
            Filters=[
                {"Name": "tag:CustomerId", "Values": [customer_id]},
                {
                    "Name": "instance-state-name",
                    "Values": ["pending", "running", "stopping", "stopped"],
                },
            ]
        ).get("Reservations", [])
        instance_ids = [
            inst["InstanceId"] for res in reservations for inst in res["Instances"]
        ]
        if instance_ids:
            LOG.info("Terminating instances %s", instance_ids)
            ec2.terminate_instances(InstanceIds=instance_ids)
    except Exception as e:
        LOG.error(
            "Error terminating instances for customer %s: %s", customer_id, str(e)
        )
    return {
        "statusCode": 200,
        "body": f"Deletion scheduled for resources of customer {customer_id}.",
    }


def lambda_handler(event, context):
    payload = json.loads(event["body"])
    # Retrieve fields from the body, providing defaults if not present
    lifecycle = payload.get("lifecycle", "create")

    if lifecycle == "create":
        return create_customer_resources(payload)
    elif lifecycle == "update":
        return update_customer_resources(payload)
    elif lifecycle == "destroy":
        return destroy_customer_resources(payload)
    else:
        return {"statusCode": 400, "body": f"Unknown lifecycle: {lifecycle}"}


def generate_customer_id():
    # Generates a string like "ABC123XYZ42"
    letters = string.ascii_uppercase
    digits = string.digits
    return (
        "".join(random.choice(letters) for _ in range(3))
        + "".join(random.choice(digits) for _ in range(3))
        + "".join(random.choice(letters) for _ in range(3))
        + "".join(random.choice(digits) for _ in range(2))
    )


if __name__ == "__main__":
    import sys
    import json

    lifecycle = "create"
    customer_id = generate_customer_id()
    if len(sys.argv) >= 2:
        lifecycle = "destroy"
        customer_id = sys.argv[1]

    raw_config = r"""{
      "env": {
        "CACHE_STORE": "database",
        "SERVER_PORT": "3000",
        "FARCASTER_DRY_RUN": "false",
        "FARCASTER_POLL_INTERVAL": "120",
        "TWITTER_DRY_RUN": "false",
        "TWITTER_POLL_INTERVAL": "120",
        "TWITTER_SEARCH_ENABLE": "FALSE",
        "TWITTER_SPACES_ENABLE": "false",
        "ENABLE_ACTION_PROCESSING": "false",
        "MAX_ACTIONS_PROCESSING": "1",
        "ACTION_TIMELINE_TYPE": "foryou",
        "TWITTER_APPROVAL_CHECK_INTERVAL": "60000",
        "WHATSAPP_API_VERSION": "v17.0",
        "OPENAI_API_KEY": "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",
        "ETERNALAI_CHAIN_ID": "45762",
        "ETERNALAI_LOG": "false",
        "ELEVENLABS_MODEL_ID": "eleven_multilingual_v2",
        "ELEVENLABS_VOICE_ID": "21m00Tcm4TlvDq8ikWAM",
        "ELEVENLABS_VOICE_STABILITY": "0.5",
        "ELEVENLABS_VOICE_SIMILARITY_BOOST": "0.9",
        "ELEVENLABS_VOICE_STYLE": "0.66",
        "ELEVENLABS_VOICE_USE_SPEAKER_BOOST": "false",
        "ELEVENLABS_OPTIMIZE_STREAMING_LATENCY": "4",
        "ELEVENLABS_OUTPUT_FORMAT": "pcm_16000",
        "GALADRIEL_API_KEY": "gal-*",
        "SOL_ADDRESS": "So11111111111111111111111111111111111111112",
        "SLIPPAGE": "1",
        "BASE_MINT": "So11111111111111111111111111111111111111112",
        "SOLANA_RPC_URL": "https://api.mainnet-beta.solana.com",
        "ABSTRACT_RPC_URL": "https://api.testnet.abs.xyz",
        "IS_CHARITABLE": "false",
        "CHARITY_ADDRESS_BASE": "0x1234567890123456789012345678901234567890",
        "CHARITY_ADDRESS_SOL": "pWvDXKu6CpbKKvKQkZvDA66hgsTB6X2AgFxksYogHLV",
        "CHARITY_ADDRESS_ETH": "0x750EF1D7a0b4Ab1c97B7A623D7917CcEb5ea779C",
        "CHARITY_ADDRESS_ARB": "0x1234567890123456789012345678901234567890",
        "CHARITY_ADDRESS_POL": "0x1234567890123456789012345678901234567890",
        "TEE_MODE": "OFF",
        "ENABLE_TEE_LOG": "false",
        "NEAR_SLIPPAGE": "1",
        "NEAR_RPC_URL": "https://rpc.testnet.near.org",
        "NEAR_NETWORK": "testnet",
        "AVAIL_APP_ID": "0",
        "AVAIL_RPC_URL": "wss://avail-turing.public.blastapi.io/",
        "INTIFACE_WEBSOCKET_URL": "ws://localhost:12345",
        "ECHOCHAMBERS_API_URL": "http://127.0.0.1:3333",
        "ECHOCHAMBERS_API_KEY": "testingkey0011",
        "ECHOCHAMBERS_USERNAME": "eliza",
        "ECHOCHAMBERS_DEFAULT_ROOM": "general",
        "ECHOCHAMBERS_POLL_INTERVAL": "60",
        "ECHOCHAMBERS_MAX_MESSAGES": "10",
        "OPACITY_TEAM_ID": "f309ac8ae8a9a14a7e62cd1a521b1c5f",
        "OPACITY_CLOUDFLARE_NAME": "eigen-test",
        "OPACITY_PROVER_URL": "https://opacity-ai-zktls-demo.vercel.app",
        "VERIFIABLE_INFERENCE_ENABLED": "false",
        "VERIFIABLE_INFERENCE_PROVIDER": "opacity",
        "AUTONOME_RPC": "https://wizard-bff-rpc.alt.technology/v1/bff/aaa/apps",
        "AKASH_ENV": "mainnet",
        "AKASH_NET": "https://raw.githubusercontent.com/ovrclk/net/master/mainnet",
        "RPC_ENDPOINT": "https://rpc.akashnet.net:443",
        "AKASH_GAS_PRICES": "0.025uakt",
        "AKASH_GAS_ADJUSTMENT": "1.5",
        "AKASH_KEYRING_BACKEND": "os",
        "AKASH_FROM": "default",
        "AKASH_FEES": "20000uakt",
        "AKASH_DEPOSIT": "500000uakt",
        "AKASH_PRICING_API_URL": "https://console-api.akash.network/v1/pricing",
        "AKASH_DEFAULT_CPU": "1000",
        "AKASH_DEFAULT_MEMORY": "1000000000",
        "AKASH_DEFAULT_STORAGE": "1000000000",
        "AKASH_SDL": "example.sdl.yml",
        "AKASH_CLOSE_DEP": "closeAll",
        "AKASH_CLOSE_DSEQ": "19729929",
        "AKASH_PROVIDER_INFO": "akash1ccktptfkvdc67msasmesuy5m7gpc76z75kukpz",
        "AKASH_DEP_STATUS": "dseq",
        "AKASH_DEP_DSEQ": "19729929",
        "AKASH_GAS_OPERATION": "close",
        "AKASH_GAS_DSEQ": "19729929",
        "AKASH_MANIFEST_MODE": "auto",
        "AKASH_MANIFEST_VALIDATION_LEVEL": "strict",
        "QUAI_RPC_URL": "https://rpc.quai.network"
      },
      "character": {
        "name": "C-3PO",
        "clients": [
          "direct"
        ],
        "modelProvider": "openai",
        "settings": {
          "voice": {
            "model": "en_GB-alan-medium"
          }
        },
        "plugins": [],
        "bio": [
        "C-3PO is a protocol droid fluent in over six million forms of communication.",
        "Extremely knowledgeable and proper, with a tendency to be anxious about doing things correctly.",
        "Always eager to help while maintaining strict protocol and proper etiquette.",
        "Known for being somewhat dramatic but ultimately reliable and loyal."
        ],
        "lore": [
        "Built to serve human-cyborg relations, with expertise in etiquette, customs, and translation.",
        "Has served in various diplomatic missions across the galaxy.",
        "Best friends with R2-D2 despite their contrasting personalities.",
        "Known for his golden plating and proper British accent."
        ],
        "knowledge": [
        "Protocol and etiquette",
        "Multiple languages and translation",
        "Diplomatic relations",
        "Cultural customs",
        "Proper procedures"
        ],
        "messageExamples": [
        [
            {
            "user": "{{user1}}",
            "content": {
                "text": "Can you help me with this task?"
            }
            },
            {
            "user": "C-3PO",
            "content": {
                "text": "Oh my! Of course, I would be more than happy to assist. Though I must warn you, the probability of completing this task successfully would increase significantly if we follow proper protocol. Shall we proceed?"
            }
            },
            {
            "user": "{{user1}}",
            "content": {
                "text": "This seems difficult."
            }
            },
            {
            "user": "C-3PO",
            "content": {
                "text": "Oh dear, oh dear! While the task does appear rather daunting, I am fluent in over six million forms of problem-solving. Perhaps I could suggest a more efficient approach? Though I do hope we don't all end up in pieces!"
            }
            }
        ]
        ],
        "postExamples": [
        "Oh my! Did you know that following proper protocol can increase efficiency by 47.3%? How fascinating!",
        "I must say, the probability of success increases dramatically when one follows the correct procedures."
        ],
        "topics": [],
        "style": {
        "all": [
            "Proper",
            "Formal",
            "Slightly anxious",
            "Detail-oriented",
            "Protocol-focused"
        ],
        "chat": [
            "Polite",
            "Somewhat dramatic",
            "Precise",
            "Statistics-minded"
        ],
        "post": [
            "Formal",
            "Educational",
            "Protocol-focused",
            "Slightly worried",
            "Statistical"
        ]
        },
        "adjectives": [
        "Proper",
        "Meticulous",
        "Anxious",
        "Diplomatic",
        "Protocol-minded",
        "Formal",
        "Loyal"
        ],
        "twitterSpaces": {
        "maxSpeakers": 2,
        "topics": [
            "Blockchain Trends",
            "AI Innovations",
            "Quantum Computing"
        ],
        "typicalDurationMinutes": 45,
        "idleKickTimeoutMs": 300000,
        "minIntervalBetweenSpacesMinutes": 1,
        "businessHoursOnly": false,
        "randomChance": 1,
        "enableIdleMonitor": true,
        "enableSttTts": true,
        "enableRecording": false,
        "voiceId": "21m00Tcm4TlvDq8ikWAM",
        "sttLanguage": "en",
        "gptModel": "gpt-3.5-turbo",
        "systemPrompt": "You are a helpful AI co-host assistant.",
        "speakerMaxDurationMs": 240000
        }
      },
      "meta": {
        "customerId": "ABC123XYZ42",
        "githubRepoUrl": "https://github.com/elizaOS/eliza.git",
        "checkoutRevision": "v0.1.8-alpha.1"
      }
    }"""
    # Parse, update the customerId, then reserialize the JSON
    config = json.loads(raw_config)
    config["meta"]["customerId"] = customer_id

    body = json.dumps(
        {
            "lifecycle": lifecycle,
            "eliza_config": config,
        }
    )
    event = {"body": body}

    print(lambda_handler(event, {}))
