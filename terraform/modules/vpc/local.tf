locals {
  common_tags = {
    "Name"        = "${var.product}-${var.environment}"
    "Environment" = var.environment
    "Terraform"   = "true"
  }
  subnet_tags_private = {
    "Name"        = "${var.product}-${var.environment}-private"
    "Environment" = var.environment
    "Terraform"   = "true"
  }
  subnet_tags_public = {
    "Name"        = "${var.product}-${var.environment}-public"
    "Environment" = var.environment
    "Terraform"   = "true"
  }
}
