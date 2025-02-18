
# Create GitHub repositories
resource "github_repository" "repos" {
  for_each    = var.repositories
  name        = each.key
  description = each.value.description

  visibility = "private"

  lifecycle {
    prevent_destroy = false
  }
}

resource "github_actions_secret" "aws_region" {
  for_each        = var.repositories
  repository      = github_repository.repos[each.key].name
  secret_name     = "AWS_REGION"
  plaintext_value = var.aws_region
}

resource "github_actions_secret" "aws_oidc_role_arn" {
  for_each        = var.repositories
  repository      = github_repository.repos[each.key].name
  secret_name     = "AWS_OIDC_ROLE_ARN"
  plaintext_value = module.iam_github_oidc_role.arn
}
