data "aws_ami" "bastion" {

  most_recent = true
  name_regex  = "^${var.environment}-bastion-.*$"
  owners      = ["self"]

}
