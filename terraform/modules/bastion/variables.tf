
variable "vpc_id" {
  type = string
}

variable "ssh_key_name" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "route53_zone_id" {
  type = string
}

variable "iam_profile" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "consul_sg" {
  type = string
}

variable "nomad_sg" {
  type = string
}

variable "environment" {
  type = string
}
