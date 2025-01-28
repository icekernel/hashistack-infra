data "aws_iam_policy_document" "ec2_describe_instances" {
  statement {
    actions = [
      "ec2:DescribeInstances"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "ec2_describe_instances" {
  name   = "${var.environment}-ec2_describe_instances"
  policy = data.aws_iam_policy_document.ec2_describe_instances.json
}

