resource "aws_key_pair" "env_ssh" {
  key_name   = local.ssh_key_name
  public_key = local.ssh_public_key
}
