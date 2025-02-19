resource "aws_iam_policy" "cloudwatch_instance_logging" {
  name        = "${var.environment}-cloudwatch-instance-logging"
  description = "Allows EC2 instances to write logs to CloudWatch"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:logs:${var.region}:${var.account_id}:log-group:${var.environment}-bastion:*",
        ]
      }
    ]
  })
}