
# module "dns" {
#   source          = "../modules/dns"
#   route53_zone_id = module.globals.route53_zone_id
# }

module "git" {
  source          = "../modules/git"
  env             = var.WORKSPACE
  github_token    = var.GITHUB_TOKEN
  github_owner    = var.GITHUB_OWNER
  repositories    = module.environment.git_repositories
}
