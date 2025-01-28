packer {
  required_plugins {
    amazon = {
      version = ">= 1.1.1"
      source  = "github.com/hashicorp/amazon"
    }
    ansible = {
      version = "~> 1"
      source = "github.com/hashicorp/ansible"
    }
  }
}

variable "ami_size" {
  type = number
  default = 8          # 8 is minimum for ubuntu
}

variable "deploy_ref" {
  type = string
  default = "main"
}

variable "environment" {
  type = string
  default = "production"
}

variable "role" {
  type = string
  default = "base"
}

variable "source_ami_filter_name" {
  type = string
  default = "ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"
}

variable "ami_tag_os_release" {
  type = string
  default = "22.04"
}

variable "ami_region" {
  type = string
  default = "eu-central-1"
}

variable "instance_type" {
  default = "t2.small"
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "${var.environment}-${var.role}-${local.timestamp}"
  instance_type = var.instance_type
  region        = "${var.ami_region}"

  temporary_key_pair_type = "ed25519"

  // ssh_keypair_name = "test1-terraform-everything-20220923"
  // ssh_private_key_file = "../ansible/plays/base/files/terraform-everything-20220923.pem"

  launch_block_device_mappings {
    device_name = "/dev/sda1"
    volume_size = var.ami_size
    delete_on_termination = true
  }

  source_ami_filter {
    filters = {
      name                = "${var.source_ami_filter_name}"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"

  tags = {
      OS_Version = "ubuntu"
      Release = "${var.ami_tag_os_release}"
      Base_AMI_Name = "{{ .SourceAMIName }}"
      Name = "${var.environment}-${var.role}-${local.timestamp}"
      Role = "${var.role}"
      Environment = "${var.environment}"
      Packer = "Use-Prism/eliza-infra"
  }

}

build {

  name = "prism1-${var.role}"

  sources = [
    "source.amazon-ebs.ubuntu"
  ]

  provisioner "ansible" {
    use_proxy = false
    playbook_file = "./${var.role}.yml"
    groups = [ "${var.role}" ]
    # Optional TODO: custom inventory to remove the --extra-vars file includes
    extra_arguments = [
#      "-vvvv",
      "--extra-vars", "@../ansible/inventories/${var.environment}/group_vars/all/default.yml",
      "--skip-tags", "packer-skip"
    ]
#    keep_inventory_file = true
    ansible_env_vars = [
      "ANSIBLE_HOST_KEY_CHECKING=False",
#      "ANSIBLE_SSH_ARGS='-o ForwardAgent=yes -o ControlMaster=auto -o ControlPersist=60s'",
      "ANSIBLE_NOCOLOR=True"
    ]

  }

}

