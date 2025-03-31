terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
  }

  required_version = ">= 1.3.10"

  # backend "remote" {
  #   hostname     = "app.terraform.io"
  #   organization = "icekernel"

  #   workspaces {
  #     prefix = "icekernelcloud01-"
  #   }
  # }

}

provider "aws" {
  region = module.environment.aws_region
}

