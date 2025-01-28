variable "environment" {
  type        = string
  description = "values: staging, production; obtained from the workspace"
}

variable "active" {
  type        = bool
  description = "If true, the RDS instance will be created"
  default     = true
}

variable "database_name" {
  type        = string
  description = "The database name"
  default     = "mydb"
}

variable "rds_config" {
  type = object({
    snapshot_id    = string
    engine         = string
    engine_version = string
    parameter_group_name = string
    enabled_cloudwatch_logs_exports = list(string)
    allocated_storage = number
    instance_class = string
  })
}

variable "latest_snapshot" {
  type        = bool
  description = "Whether we pull from the latest snapshot given rds identifier"
  default     = true
}

variable "named_snapshot" {
  type = bool
  description = "Whether we pull from some a named snapshot. cannot be used with latest_snapshot"
  default = false
}

variable "nomad_security_group" {
  type        = string
  description = "The security group id for the Nomad cluster"
}

variable "bastion_security_group" {
  type        = string
  description = "The security group id for the Bastion host"
}

variable "vpc_id" {
  type        = string
  description = "The VPC id"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "The private subnet ids"
}

variable "rds_username" {
  type        = string
  description = "The RDS username"
  default     = "admin"
}

variable "rds_password" {
  type        = string
  description = "The RDS password"
  default     = "admin123"
}