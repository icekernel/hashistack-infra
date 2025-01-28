output "docker_sg" {
  description = "security group that allows db access"
  value       = aws_security_group.docker.id
}
