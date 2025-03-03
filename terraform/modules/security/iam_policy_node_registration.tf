

resource "aws_iam_policy" "node_registration" {
  name        = "${var.environment}-node-registration"
  description = "Allows instances to read node registration secrets"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:secretsmanager:${var.region}:${var.account_id}:secret:/${var.environment}/consul/node_registration*",
          "arn:aws:secretsmanager:${var.region}:${var.account_id}:secret:/${var.environment}/consul/nomad_agents*",
          "arn:aws:secretsmanager:${var.region}:${var.account_id}:secret:/${var.environment}/consul/vault_server_registration*",
          "arn:aws:secretsmanager:${var.region}:${var.account_id}:secret:/${var.environment}/nomad/client_token*",
          "arn:aws:secretsmanager:${var.region}:${var.account_id}:secret:/${var.environment}/vault/agent_token*",
        ]
      }
    ]
  })
}
