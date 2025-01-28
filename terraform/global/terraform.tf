terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.23"
    }
  }

  required_version = ">= 1.2.5"

  # backend "remote" {
  #   hostname     = "app.terraform.io"
  #   organization = "prism"

  #   workspaces {
  #     prefix = "prism1-"
  #   }
  # }

}

provider "aws" {
  region = module.environment.aws_region
}

