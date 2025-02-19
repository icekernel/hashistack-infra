resource "aws_iam_policy" "ec2_describe_instances" {
  name        = "${var.environment}-ec2-describe-instances"
  description = "Allows EC2 instances to describe other instances"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}