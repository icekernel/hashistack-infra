data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_route53_zone" "zone" {
  name         = var.domain
  private_zone = "false"
}

