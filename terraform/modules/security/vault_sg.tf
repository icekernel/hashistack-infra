resource "aws_security_group" "vault" {
  name        = "${var.environment}-vault"
  description = "All required ports for vault are allowed for members of the security group"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "vault_client_tcp" {
  type = "ingress"
  from_port = 8200
  to_port   = 8200
  protocol  = "tcp"
  cidr_blocks = [ "0.0.0.0/0" ]
  security_group_id = aws_security_group.vault.id
}

resource "aws_security_group_rule" "vault_server_tcp" {
  type = "ingress"
  from_port = 8201
  to_port   = 8201
  protocol  = "tcp"
  self = true
  security_group_id = aws_security_group.vault.id
}

output "vault_sg" {
  description = "EC2 Security Group for vault"
  value       = aws_security_group.vault.id
}