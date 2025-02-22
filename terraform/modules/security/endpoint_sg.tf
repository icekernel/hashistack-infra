resource "aws_security_group" "endpoint_sg" {
  name        = "${var.environment}-endpoint"
  description = "Allow inbound traffic to self referencign group"
  vpc_id      = var.vpc_id

  # allow all from self
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # allows all protocols
    self        = true
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    "Name" = "${var.environment}-endpoint"
    "Environment" = var.environment
    "Terraform" = "UsePrism/eliza-infra"
  }
}
