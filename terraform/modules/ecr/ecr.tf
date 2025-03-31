locals {
  prefix = "${var.env}-${var.context_prefix}"
  tags = {
    Provisioner = "terraform"
    Environment = var.env
    Repository  = "https://github.com/icekernel/hashistack-infra"
  }
  ecr_repositories = flatten([
    for repo_name, repo_data in var.repositories : [
      "${local.prefix}-${repo_name}"
    ]
  ])
}

module "ecr_repositories" {
  source = "terraform-aws-modules/ecr/aws"

  for_each = toset(local.ecr_repositories)

  repository_name = "${local.prefix}-${each.value}"

  repository_image_tag_mutability = "IMMUTABLE"

  repository_force_delete = true

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["githash-"],
          countType     = "imageCountMoreThan",
          countNumber   = 30
        },
        action = {
          type = "expire"
        }
      },
    ]
  })

  tags = local.tags
}

