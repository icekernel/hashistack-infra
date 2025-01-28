data "aws_ami" "eliza" {

  most_recent = true
  name_regex  = "^${local.instance_name}-.*$"
  owners      = ["self"]

}
