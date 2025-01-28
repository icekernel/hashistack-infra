variable "environment" {
  type        = string
  description = "values: staging, production; obtained from the workspace"
}

variable "product" {
  type        = string
  description = "The product name"
  default     = "myapp"
}

variable "aws_region" {
  description = "AWS region for the environment"
  type        = string
}

variable "resource_name_prefix" {
  description = "Prefix for all resources"
  type        = string
  default     = "myapp"
}

variable "private_subnet_cidrs" {
  description = "CIDRs for private subnets"
  type        = list(string)
  default = [
    "10.0.0.0/19",
    "10.0.32.0/19",
    "10.0.64.0/19",
  ]
}

variable "public_subnet_cidrs" {
  description = "CIDRs for public subnets"
  type        = list(string)
  default = [
    "10.0.128.0/20",
    "10.0.144.0/20",
    "10.0.160.0/20",
  ]
}

variable "vpc_cidr" {
  description = "CIDR for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}
