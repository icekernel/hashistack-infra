import requests
import logging
from cloudinit import subp
from cloudinit.config.schema import MetaSchema
from cloudinit.config import Config
from cloudinit.cloud import Cloud
from cloudinit.settings import PER_INSTANCE
from textwrap import dedent

LOG = logging.getLogger(__name__)


def load_environment_variables():
    env_vars = {}
    with open("/etc/environment", "r") as file:
        for line in file:
            # Skip comments and empty lines
            if line.startswith("#") or not line.strip():
                continue
            # Parse key-value pairs
            key, value = line.strip().split("=", 1)
            env_vars[key] = value
    return env_vars


def fetch_imds_token():
    try:
        url = "http://169.254.169.254/latest/api/token"
        headers = {"X-aws-ec2-metadata-token-ttl-seconds": "21600"}
        response = requests.put(url, headers=headers, timeout=5)
        response.raise_for_status()
        return response.text.strip()
    except Exception as e:
        LOG.error("Failed to fetch IMDS token: %s", str(e))
        return None


def fetch_ipv4(token: str = None):
    try:
        url = "http://169.254.169.254/latest/meta-data/local-ipv4"
        headers = {}
        if token:
            headers = {"X-aws-ec2-metadata-token": token}
        response = requests.get(url, headers=headers, timeout=5)
        response.raise_for_status()
        return response.text.strip()
    except Exception as e:
        LOG.error("Failed to fetch local IPv4 address: %s", str(e))
        return None


MODULE_DESCRIPTION = """\
This module sets instance's hostname based on its role, environment, and ip address.
"""

meta: MetaSchema = {
    "id": "cc_set_custom_hostname",
    "name": "Set custom hostname",
    "title": "Sets instance's hostname based on its role, environment, and ip address",
    "distros": ["all"],
    "description": MODULE_DESCRIPTION,
    "examples": [
        dedent(
            """
            # cloud-config
            cloud_config_modules:
                - set_custom_hostname
            """
        ),
    ],
    "frequency": PER_INSTANCE,
    "activate_by_schema_keys": [],
}


def handle(name: str, cfg: Config, cloud: Cloud, args: list) -> None:
    token = fetch_imds_token()
    ipv4 = fetch_ipv4(token)
    LOG.debug("Fetched IPv4: '%s'", ipv4)
    if not ipv4:
        LOG.error("Empty IPv4 address received from metadata service")
        return

    environ = load_environment_variables()
    environment = environ.get("ENVIRONMENT", "unknown")
    role = environ.get("ROLE", "unknown")

    host = ipv4.replace(".", "-")
    hostname = f"{environment}-{role}-{host}"
    LOG.debug("Setting hostname to: %s", hostname)

    try:
        with open("/etc/hostname", "w") as file:
            file.write(hostname)

        with open("/etc/hosts", "a") as file:
            file.write(f"127.0.0.1 {hostname}\n")

        subp.subp(["hostname", hostname], capture=True)
        LOG.info("Hostname successfully set to %s", hostname)
    except Exception as e:
        LOG.error("Unexpected error while setting hostname: %s", str(e))
