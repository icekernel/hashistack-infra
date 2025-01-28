import requests
import logging
from cloudinit import subp
from cloudinit.config.schema import MetaSchema, get_meta_doc
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

__doc__ = get_meta_doc(meta)


def handle(name: str, cfg: Config, cloud: Cloud, args: list) -> None:
    try:
        # Fetch instance's local IPv4 address
        ipv4 = requests.get("http://169.254.169.254/latest/meta-data/local-ipv4").text
    except requests.RequestException as e:
        LOG.error("Failed to fetch instance's local IPv4 address: %s", str(e))

    environ = load_environment_variables()
    environment = environ.get("ENVIRONMENT", "unknown")
    role = environ.get("ROLE", "unknown")

    host = ipv4.replace(".", "-")
    hostname = f"{environment}-{role}-{host}"
    LOG.debug("Setting hostname to: %s", hostname)

    with open("/etc/hostname", "w") as file:
        file.write(hostname)

    with open("/etc/hosts", "a") as file:
        file.write(f"127.0.0.1 {hostname}\n")

    try:
        subp.subp(["hostname", hostname], capture=True)
    except subp.ProcessExecutionError as e:
        LOG.error("Failed to set hostname: %s", str(e))
        raise
