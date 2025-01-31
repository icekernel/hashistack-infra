data "aws_ami" "nginx" {

  most_recent = true
  name_regex  = "^${local.instance_name}-.*$"
  owners      = ["self"]

}
