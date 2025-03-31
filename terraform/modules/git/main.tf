provider "github" {
  token = var.github_token
  owner = var.github_owner
}

locals {
  prefix = "${var.env}-${var.context_prefix}"
  tags = {
    Provisioner = "terraform"
    Environment = var.env
    Repository  = "https://github.com/icekernel/hashistack-infra"
  }
}

module "iam_github_oidc_provider" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-provider"

  tags = local.tags
}

locals {
  allowed_repositories = [ for key, value in var.repositories : "${var.github_owner}/${key}:*" ]
}

module "iam_github_oidc_role" {
  source    = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"

  name = "${local.prefix}-github-oidc-role"

  subjects = local.allowed_repositories

  # TODO: replace with a restrisctive policy
  policies = {
    Administrator = "arn:aws:iam::aws:policy/AdministratorAccess"
  }

  tags = local.tags
}