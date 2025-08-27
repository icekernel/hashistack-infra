# Packer build scripts for picksups.click AMIs

## Requirements

Ensure you have packer and ansible installed:

```bash
cd $(git rev-parse --show-toplevel)  # Go to project root
pkenv install 1.8.2
pyenv install 3.10.2
```

Set up the Python environment for Ansible:

```bash
python -m venv venv
. venv/bin/activate
cd ansible
pip install -r requirements.txt
```

## Building AMIs

### Build Script Convention

Scripts are named using the pattern: `<env>-<role>.sh`
- `env`: Environment (prod1, prod2, test1, test2)
- `role`: Instance role (bastion, docker, eliza, nginx)

### Available Build Scripts

#### Production Environment (prod1)
```bash
./prod1-bastion.sh  # Build bastion host AMI
./prod1-docker.sh   # Build Docker host AMI
./prod1-eliza.sh    # Build Eliza application AMI
./prod1-nginx.sh    # Build Nginx proxy AMI
```

#### Production Environment (prod2)
```bash
./prod2-bastion.sh  # Build bastion host AMI
./prod2-docker.sh   # Build Docker host AMI
```

#### Test Environment (test1)
```bash
./test1-bastion.sh  # Build bastion host AMI
./test1-docker.sh   # Build Docker host AMI
./test1-eliza.sh    # Build Eliza application AMI
./test1-nginx.sh    # Build Nginx proxy AMI
```

#### Test Environment (test2)
```bash
./test2-bastion.sh  # Build bastion host AMI
./test2-docker.sh   # Build Docker host AMI
```

### Manual Build

To build manually with custom parameters:

```bash
packer build -on-error=ask \
  -var-file="env-<environment>.pkrvars.hcl" \
  -var-file="<role>.pkrvars.hcl" \
  base.pkr.hcl
```

## Build Process

The build process:
1. Launches a temporary EC2 instance
2. Runs Ansible playbooks to configure the instance
3. Creates an AMI from the configured instance
4. Terminates the temporary instance

Build logs will show the AMI ID upon successful completion.
