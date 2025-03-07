# HashiVault EC2 instance auth needs this
resource "aws_iam_policy" "iam_get_roles" {
  name        = "${var.environment}-iam-get-roles"
  description = "Allows EC2 instances to get IAM roles"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "iam:GetRole",
          "iam:ListRoles"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}