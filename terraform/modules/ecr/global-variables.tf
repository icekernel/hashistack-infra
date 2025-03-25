variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "eu-central-1"
}

variable "context_prefix" {
  description = "The prefix to use for all resources"
  type        = string
  default     = "eliza"
}

variable "env" {
  type = string
}