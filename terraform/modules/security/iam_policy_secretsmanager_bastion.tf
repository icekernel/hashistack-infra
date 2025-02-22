resource "aws_iam_policy" "secretsmanager_bastion" {
  name        = "${var.environment}-secretsmanager-bastion"
  description = "Allows bastion instances to manage secrets in Secrets Manager for their own environment"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecret",
          "secretsmanager:CreateSecret",
          "secretsmanager:DeleteSecret",
          "secretsmanager:GetResourcePolicy",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:secretsmanager:${var.region}:${var.account_id}:secret:${var.environment}/*"
        Resource = "arn:aws:secretsmanager:${var.region}:${var.account_id}:secret:/${var.environment}/*"
      }
    ]
  })
}
