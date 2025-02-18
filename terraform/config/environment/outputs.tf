
output "aws_region" {
  value = local.aws_region[var.environment]
}

output "bastion_instance_type" {
  value = local.bastion_instance_type[var.environment]
}

output "eliza_instance_type" {
  value = local.eliza_instance_type[var.environment]
}

output "nginx_instance_type" {
  value = local.nginx_instance_type[var.environment]
}

output "docker_instance_type" {
  value = local.docker_instance_type[var.environment]
}

output "git_repositories" {
  value = local.git_repositories[var.environment]
}