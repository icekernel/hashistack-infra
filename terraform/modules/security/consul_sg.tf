resource "aws_security_group" "consul" {

  name        = "${var.environment}-consul"
  description = "All required ports for Consul are allowed for members of the security group"
  vpc_id      = var.vpc_id

}

resource "aws_security_group_rule" "consul_dns_tcp" {
  # consul dns tcp
  type = "ingress"
  from_port = 8600
  to_port   = 8600
  protocol  = "tcp"
  self      = true
  security_group_id = aws_security_group.consul.id
}

resource "aws_security_group_rule" "consul_dns_udp" {
  # consul dns udp
  type = "ingress"
  from_port = 8600
  to_port   = 8600
  protocol  = "udp"
  self      = true
  security_group_id = aws_security_group.consul.id
}

resource "aws_security_group_rule" "consul_http_api" {
  # consul http api
  type = "ingress"
  from_port = 8500
  to_port   = 8500
  protocol  = "tcp"
  self      = true
  security_group_id = aws_security_group.consul.id
}

resource "aws_security_group_rule" "consul_serf_tcp" {
  # consul lan serf and wan serf - tcp
  type = "ingress"
  from_port = 8300
  to_port   = 8302
  protocol  = "tcp"
  self      = true
  security_group_id = aws_security_group.consul.id
}

resource "aws_security_group_rule" "consul_serf_udp" {
  type = "ingress"
  from_port = 8301
  to_port   = 8302
  protocol = "udp"
  self = true
  security_group_id = aws_security_group.consul.id
}

resource "aws_security_group_rule" "consul_rpc_tcp" {
  # consul rpc
  type = "ingress"
  from_port = 8300
  to_port   = 8300
  protocol  = "tcp"
  cidr_blocks = [ "0.0.0.0/0" ]
  security_group_id = aws_security_group.consul.id
}

resource "aws_security_group_rule" "consul_sidecar_tcp" {
  # sidecar proxy min/max ports
  type = "ingress"
  from_port = 21000
  to_port   = 21255
  protocol  = "tcp"
  self      = true
  security_group_id = aws_security_group.consul.id
}

output "consul_sg" {
  description = "EC2 Security Group for consul"
  value       = aws_security_group.consul.id
}