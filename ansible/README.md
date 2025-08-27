# Ansible Configuration Management

This directory contains Ansible playbooks and configurations for managing the HashiCorp stack infrastructure.

## Prerequisites

### Galaxy Collections

Install the required Ansible Galaxy collections:

```bash
ansible-galaxy collection install -r galaxy-collections.list
```

Check [galaxy-collections.list](galaxy-collections.list) for specific versions.

## Quick Start

### Testing Connectivity

Verify connection to all hosts:

```bash
ansible all -m ping
```

### Running Playbooks

Apply the Eliza role playbook:

```bash
ansible-playbook plays/role/eliza/main.yml
```

Apply all configurations:

```bash
ansible-playbook -i inventories/<environment>/aws_ec2.yml all.yml
```

## Execution Modes

Ansible is configured to run in three different modes in this [hashistack-infra](https://github.com/icekernel/hashistack-infra) repository:

### 1. Pull Mode
Instances pull their configuration directly from the repository. Used for self-updating infrastructure.

### 2. Push Mode
Traditional Ansible approach where the control node pushes configuration to target hosts. Used for development and immediate updates.

### 3. Packer Mode
Used during AMI building. Playbooks are executed as part of the image creation process.

The [`../packer/`](../packer/) directory pulls plays from this Ansible directory, ensuring configuration consistency across all execution modes.

Note: While not every playbook needs to run in all modes, they should be able to execute properly, especially useful for running in check mode against instances.

## Development Workflow

### Building AMIs

AMI building is handled by Packer. See [`../packer/`](../packer/) for details.

### Developing Playbooks

1. **Initial Setup**: Spin up a new stack with a basic instance (e.g., nginx on port 80)
2. **Development**: Use Ansible push mode to iteratively develop and test playbooks
3. **Validation**: Ensure the playbook runs successfully with Packer
4. **Deployment**: Launch stack with the newly built AMI

### Future Improvements

- Add Molecule for testing
- Support for VirtualBox or containerd environments

## Directory Structure

- `plays/` - Playbook definitions organized by function
  - `base/` - Base system configuration
  - `role/` - Role-specific configurations (bastion, docker, eliza, nginx)
  - `pull/` - Pull-mode specific plays
  - `push/` - Push-mode specific plays
- `inventories/` - Environment-specific inventory configurations
- `bin/` - Certificate and key rotation scripts
