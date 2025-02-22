resource "aws_eip" "nat" {
  #  count = length(data.aws_availability_zones.available)
  count = 1
  domain = "vpc"
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source             = "terraform-aws-modules/vpc/aws"
  version            = "5.5.3"
  name               = "${var.product}-${var.environment}"
  cidr               = var.vpc_cidr
  azs                = data.aws_availability_zones.available.names
  enable_nat_gateway = true
  #  single_nat_gateway      = false
  single_nat_gateway = true
  #  one_nat_gateway_per_az  = true
  reuse_nat_ips           = true
  external_nat_ip_ids     = aws_eip.nat.*.id
  map_public_ip_on_launch = false
  private_subnets         = var.private_subnet_cidrs
  public_subnets          = var.public_subnet_cidrs

  tags = local.common_tags

  private_subnet_tags = local.subnet_tags_private
  public_subnet_tags  = local.subnet_tags_public

  # DHCP Options are delicate stuff
  enable_dhcp_options              = true
  dhcp_options_domain_name         = "node.consul"
  # dhcp_options_domain_name_servers = ["127.0.0.1"]

}
