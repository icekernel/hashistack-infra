output "ssh_key_name" {
  description = "SSH Key for provisioning"
  value       = aws_key_pair.env_ssh.key_name
}

output "iam_instance_profile_bastion" {
  description = "IAM Instance for bastion"
  value       = aws_iam_instance_profile.bastion.name
}

output "iam_instance_profile_docker" {
  description = "IAM Instance for bastion"
  value       = aws_iam_instance_profile.docker.name
}

output "iam_instance_profile_arn_docker" {
  description = "IAM Instance for docker"
  value       = aws_iam_instance_profile.docker.arn
}

output "iam_instance_profile_arn_eliza" {
  description = "IAM Instance for eliza"
  value       = aws_iam_instance_profile.eliza.arn
}

output "iam_instance_profile_arn_nginx" {
  description = "IAM Instance for nginx"
  value       = aws_iam_instance_profile.nginx.arn
}
