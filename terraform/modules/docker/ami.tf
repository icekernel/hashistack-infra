data "aws_ami" "docker" {

  most_recent = true
  name_regex  = "^${local.instance_name}-.*$"
  owners      = ["self"]

}
