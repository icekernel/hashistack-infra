resource "aws_security_group" "nomad" {

  name        = "${var.environment}-nomad"
  description = "All required ports for nomad are allowed for members of the security group"
  vpc_id      = var.vpc_id

}

resource "aws_security_group_rule" "nomad_http_api" {
  # nomad http api
  type              = "ingress"
  from_port         = 4646
  to_port           = 4646
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.nomad.id
}

resource "aws_security_group_rule" "nomad_rpc_tcp" {
  # nomad rpc tcp
  type              = "ingress"
  from_port         = 4647
  to_port           = 4647
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.nomad.id
}

resource "aws_security_group_rule" "nomad_serf_tcp" {
  # nomad lan serf and wan serf - tcp
  type              = "ingress"
  from_port         = 4648
  to_port           = 4648
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.nomad.id
}

resource "aws_security_group_rule" "nomad_serf_udp" {
  type              = "ingress"
  from_port         = 4648
  to_port           = 4648
  protocol          = "udp"
  self              = true
  security_group_id = aws_security_group.nomad.id
}

resource "aws_security_group_rule" "nomad_dynamic_ports_tcp" {
  type              = "ingress"
  from_port         = 20000
  to_port           = 32000
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.nomad.id
}

resource "aws_security_group_rule" "nomad_dynamic_ports_udp" {
  type              = "ingress"
  from_port         = 20000
  to_port           = 32000
  protocol          = "udp"
  self              = true
  security_group_id = aws_security_group.nomad.id
}

output "nomad_sg" {
  description = "EC2 Security Group for nomad"
  value       = aws_security_group.nomad.id
}
