resource "aws_kms_key" "vault" {
  description             = "KMS key for Vault auto-unseal"
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "vault" {
  name          = "alias/vault-${var.environment}"
  target_key_id = aws_kms_key.vault.key_id
}

data "aws_iam_policy_document" "kms_bastion" {
  statement {
    sid    = "AllowUseOfTheKey"
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = [aws_kms_key.vault.arn]
  }

  statement {
    sid    = "AllowAttachmentOfPersistentResources"
    effect = "Allow"

    actions = [
      "kms:ListGrants",
      "kms:CreateGrant"
    ]

    resources = [aws_kms_key.vault.arn]

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }
}

resource "aws_iam_policy" "kms_bastion" {
  name        = "${var.environment}-kms-bastion"
  description = "Policy for Bastion to use KMS for Vault auto-unseal"
  policy      = data.aws_iam_policy_document.kms_bastion.json
}
