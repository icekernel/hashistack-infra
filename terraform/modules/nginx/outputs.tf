output "nginx_sg" {
  description = "security group that allows nginx access"
  value       = aws_security_group.nginx.id
}
