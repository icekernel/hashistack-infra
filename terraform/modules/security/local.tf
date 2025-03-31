locals {
  ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOAUrFza+VYkiEuhal2Lx++jGJUxphNjYDtLLhvM39Iu conrado+aws-ice01@icekernel.com"
  ssh_key_name   = "${var.environment}-icekernelcloud01-20250331"
}
