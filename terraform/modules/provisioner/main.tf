locals {
  lambda_full_name = "${var.env}-${var.lambda_function}"
}
variable "env" {
  description = "Environment name. dev or prod."
  type = string
}

variable "subnet_ids" {
  description = "List of subnet IDs to deploy the Lambda function."
  type = list(string)
}

variable "security_group" {
  description = "Security group ID for the Lambda function."
  type = string
}

######## START: Lambda block
variable "src_path" {
  description = "Path to the Lambda function source code."
  type = string
}
variable "lambda_function" {
  description = "Name of the Lambda function. convention: <service>-<function>-healthcheck, e.g. airflow-webserver-healthcheck."
  type = string
}
variable "python_version" {
  default = "3.12"
  description = "Python version to use for the Lambda function."
}
variable "EXTRA_ENV_VARS" {
  type = map(string)
  description = "values to be added to the environment variables of the Lambda function. Example: {\"TARGET_HOST_OVERRIDE\" = \"example.com\"}"
  default = {}
}
variable "lambda_timeout" {
  default = 30
  description = "The amount of time your Lambda Function has to run in seconds."
}
variable "lambda_memory" {
  default = 128
}

variable "build_in_docker" {
  description = "lets you build the lambda package in a docker container"
  default = false
}
######## END: Lambda block
