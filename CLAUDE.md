# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a HashiCorp stack (Consul, Nomad, Vault) infrastructure repository for managing icekernelcloud01.com. It uses Terraform for infrastructure provisioning, Packer for AMI building, and Ansible for configuration management.

## Key Components

### Infrastructure Stack
- **Consul**: Service mesh and discovery
- **Nomad**: Container orchestration
- **Vault**: Secrets management
- **Traefik**: Load balancing and routing
- **Eliza**: Custom application deployment

### Directory Structure
- `terraform/`: Infrastructure as code
  - `environments/`: Environment-specific configurations (prod1, test1)
  - `modules/`: Reusable Terraform modules (vpc, security, bastion, eliza, nginx, etc.)
  - `global/`: Global infrastructure resources
- `packer/`: AMI building configurations for base, bastion, docker, eliza, nginx
- `ansible/`: Configuration management playbooks
  - `plays/`: Playbook definitions for different roles
  - `inventories/`: Environment-specific inventory configurations
- `bin/`: Helper scripts for instance management
- `src/`: Lambda functions for provisioning and authentication

## Common Commands

### Terraform Operations
```bash
# Switch workspace (environments: prod1, test1)
cd terraform/environments
terraform workspace select prod1  # or test1

# Plan infrastructure changes
terraform plan

# Apply infrastructure changes
terraform apply

# Taint resources for recreation
./terraform/bin/taint-bastion.sh
./terraform/bin/taint-eliza.sh
```

### Packer AMI Building
```bash
cd packer

# Build AMIs for different environments
./prod1-bastion.sh  # Build bastion AMI for prod1
./prod1-docker.sh   # Build docker AMI for prod1
./prod1-eliza.sh    # Build eliza AMI for prod1
./prod1-nginx.sh    # Build nginx AMI for prod1

# Test environment
./test1-bastion.sh
./test1-docker.sh
./test1-eliza.sh
./test1-nginx.sh
```

### Ansible Configuration
```bash
cd ansible

# Install Python dependencies
python -m venv venv
. venv/bin/activate
pip install -r requirements.txt

# Install required Ansible Galaxy collections (check galaxy-collections.list for versions)
ansible-galaxy collection install -r galaxy-collections.list

# Run playbooks against inventory
ansible-playbook -i inventories/prod1/aws_ec2.yml all.yml

# Test connectivity to all hosts
ansible all -m ping

# Apply specific role playbooks
ansible-playbook plays/role/eliza/main.yml
```

### Instance Management
```bash
# Launch new Eliza instance
./bin/launch-eliza-instance.sh <STAGE> <CUSTOMER_ID>

# Update Eliza instance
./bin/update-eliza-instance.sh <STAGE> <CUSTOMER_ID>

# Destroy Eliza instance
./bin/destroy-eliza-instance.sh <STAGE> <CUSTOMER_ID>

# List backups
./bin/list-backups.sh
```

### Certificate and Key Rotation (Ansible)
```bash
cd ansible/bin

# Rotate Consul certificates
./rotate-consul-ca.sh
./rotate-consul-certs.sh
./rotate-consul-gossip-key.sh

# Rotate Nomad certificates
./rotate-nomad-ca.sh
./rotate-nomad-certs.sh
./rotate-nomad-gossip-key.sh
```

## Architecture Patterns

### Multi-Environment Setup
The infrastructure supports multiple environments (prod1, test1) using Terraform workspaces. Each environment has:
- Dedicated VPC with public/private subnets
- Bastion hosts for secure access
- Consul/Nomad clusters for orchestration
- Application instances (Eliza, Nginx)

### Module-Based Architecture
Terraform modules encapsulate infrastructure components:
- `vpc`: Network infrastructure
- `security`: IAM roles, security groups, KMS keys
- `bastion`: Jump hosts for secure access
- `eliza`: Application infrastructure with S3 buckets
- `nginx`: Web server infrastructure
- `provisioner`: Lambda-based provisioning via API Gateway
- `endpoints`: VPC endpoints for AWS services

### Configuration Management
Ansible playbooks manage:
- Base system configuration (packages, swap, monitoring)
- HashiStack installation and configuration (Consul, Nomad, Vault)
- Application deployment (Eliza, Docker, Nginx)
- Pull-based configuration updates

### Instance Provisioning
Custom provisioning system using:
- API Gateway endpoints for lifecycle management
- Lambda functions for orchestration
- Dynamic instance creation with customer-specific configurations

## Agent Provisioner API

The agent provisioner API is available as a Lambda function proxied by API Gateway. It manages agent lifecycle through JSON payloads:

```bash
# Destroy an instance
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "lifecycle": "destroy",
    "meta": {
      "customerId": "ABC123XYZ42"
    }
  }' \
  https://<api-endpoint>/prod1/provisioner

# Access launched agents
# Agents become available at:
https://prod1-nginx.icekernelcloud01.com/<customerId>/agents
```

## Ansible Execution Modes

Ansible is configured for three different modes:
- **pull**: Instances pull configuration from repository
- **push**: Push configuration to instances from control node
- **packer**: Build-time configuration for AMI creation

## Development Workflow

1. Spin up a new stack with basic nginx instance
2. Use Ansible push mode to develop and test playbooks
3. Build new AMI with Packer once playbook is stable
4. Launch stack with new AMI

## Important Notes

- Terraform state is managed locally with workspace separation
- AMIs are built with Packer and referenced in Terraform modules
- Ansible uses dynamic AWS inventory for targeting instances
- Certificates and keys are managed in `ansible/plays/base/files/`
- Environment variables are set via Terraform workspace (var.WORKSPACE)
- Playbooks are designed to work across all execution modes (pull/push/packer)