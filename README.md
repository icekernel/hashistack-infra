# Infra for icekernelcloud01.com

HashiCorp stack infrastructure for managing icekernelcloud01.com using Terraform, Packer, and Ansible.

## Prerequisites

### Required Tools

Install the following tools using Homebrew:

```bash
brew install consul nomad cfssl tfenv pkenv pyenv
```

### Version Configuration

This repository requires specific versions:

```bash
tfenv install 1.2.5
pkenv install 1.8.2
pyenv install 3.10.2
```

### Python Environment Setup

Set up the Python environment for Ansible:

```bash
cd ./ansible
python -m venv venv
. venv/bin/activate
pip install -r requirements.txt
```

## Quick Start

### Terraform Operations

To work with the infrastructure:

```bash
cd ./terraform/environments

# Select environment workspace (prod1 or test1)
terraform workspace select prod1

# Review planned changes
terraform plan

# Apply infrastructure changes
terraform apply
```

### Building AMIs

Use the provided scripts in the `packer/` directory:

```bash
cd ./packer
./prod1-eliza.sh  # Build Eliza AMI for production
```

### Managing Instances

Helper scripts are available in the `bin/` directory:

```bash
./bin/launch-eliza-instance.sh <STAGE> <CUSTOMER_ID>
./bin/update-eliza-instance.sh <STAGE> <CUSTOMER_ID>
./bin/destroy-eliza-instance.sh <STAGE> <CUSTOMER_ID>
```

## Project Structure

- `terraform/` - Infrastructure as Code (Terraform modules and environments)
- `packer/` - AMI build configurations
- `ansible/` - Configuration management playbooks
- `bin/` - Helper scripts for operations
- `docs/` - Additional documentation
- `src/` - Lambda functions for provisioning

## Documentation

- [Ansible Configuration](./ansible/README.md)
- [Packer Build Process](./packer/README.md)
- [API Documentation](./docs/README.md)
