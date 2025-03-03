locals {
  common_tags = {
    Product     = var.product
    Environment = var.environment
    Terraform   = "UsePrism/eliza-infra"
  }
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.secretsmanager"
  vpc_endpoint_type = "Interface"

  subnet_ids = var.private_subnets

  security_group_ids = var.aws_api_endpoint_sgs

  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${var.product}-${var.environment}-secretsmanager-endpoint"
  })
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ssm"
  vpc_endpoint_type = "Interface"

  subnet_ids = var.private_subnets

  security_group_ids = var.aws_api_endpoint_sgs

  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${var.product}-${var.environment}-ssm-endpoint"
  })
}

resource "aws_vpc_endpoint" "ec2" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ec2"
  vpc_endpoint_type = "Interface"

  subnet_ids = var.private_subnets

  security_group_ids = var.aws_api_endpoint_sgs

  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${var.product}-${var.environment}-ec2-endpoint"
  })
}

resource "aws_vpc_endpoint" "kms" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.kms"
  vpc_endpoint_type = "Interface"

  subnet_ids = var.private_subnets

  security_group_ids = var.aws_api_endpoint_sgs

  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${var.product}-${var.environment}-kms-endpoint"
  })
}

data "aws_region" "current" {}
