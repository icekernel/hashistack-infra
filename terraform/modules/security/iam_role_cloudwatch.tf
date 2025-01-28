data "aws_iam_policy_document" "cloudwatch_instance_logging" {
  statement {
    actions = [
      "logs:PutRetentionPolicy",
      "logs:PutLogEvents",
      "cloudwatch:PutMetricData",
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "cloudwatch_instance_logging" {
  name   = "${var.environment}-cloudwatch_instance_logging"
  policy = data.aws_iam_policy_document.cloudwatch_instance_logging.json
}
