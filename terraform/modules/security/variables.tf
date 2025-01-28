
variable "region" {
  type = string
}

variable "account_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "environment" {
  type        = string
  description = "values: staging, production; to be obtained from the workspace"
}
