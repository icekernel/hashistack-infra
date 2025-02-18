output "github_oicd_role_arn" {
  value = module.iam_github_oidc_role.arn
}

output "git_repositories" {
  value = var.repositories
}
