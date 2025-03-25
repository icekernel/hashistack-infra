module "vpc" {
  source      = "../modules/vpc"
  aws_region  = module.environment.aws_region
  product     = module.globals.product
  environment = var.WORKSPACE
}

module "security" {
  source      = "../modules/security"
  region      = module.environment.aws_region
  account_id  = module.globals.account_id
  vpc_id      = module.vpc.vpc_id
  environment = var.WORKSPACE
}

module "endpoints" {
  source           = "../modules/endpoints"
  aws_region       = module.environment.aws_region
  vpc_id           = module.vpc.vpc_id
  private_subnets  = module.vpc.private_subnets
  aws_api_endpoint_sgs      = [module.security.endpoint_sg]
  environment      = var.WORKSPACE
  product          = module.globals.product
}

module "bastion" {
  source          = "../modules/bastion"
  vpc_id          = module.vpc.vpc_id
  ssh_key_name    = module.security.ssh_key_name
  public_subnets  = module.vpc.public_subnets
  private_subnets = module.vpc.private_subnets
  route53_zone_id = module.globals.route53_zone_id
  iam_profile     = module.security.iam_instance_profile_bastion
  instance_type   = module.environment.bastion_instance_type
  consul_sg       = module.security.consul_sg
  nomad_sg        = module.security.nomad_sg
  endpoint_sg     = module.security.endpoint_sg
  vault_sg        = module.security.vault_sg
  environment     = var.WORKSPACE
}


module "eliza" {
  source          = "../modules/eliza"
  vpc_id          = module.vpc.vpc_id
  ssh_key_name    = module.security.ssh_key_name
  public_subnets  = module.vpc.public_subnets
  private_subnets = module.vpc.private_subnets
  route53_zone_id = module.globals.route53_zone_id
  consul_sg       = module.security.consul_sg
  nomad_sg        = module.security.nomad_sg
  bastion_sg      = module.bastion.bastion_sg
  endpoint_sg     = module.security.endpoint_sg
  iam_profile     = module.security.iam_instance_profile_arn_eliza
  instance_type   = module.environment.eliza_instance_type
  domain          = module.globals.domain
  environment     = var.WORKSPACE
}

module "nginx" {
  source          = "../modules/nginx"
  vpc_id          = module.vpc.vpc_id
  ssh_key_name    = module.security.ssh_key_name
  public_subnets  = module.vpc.public_subnets
  private_subnets = module.vpc.private_subnets
  route53_zone_id = module.globals.route53_zone_id
  consul_sg       = module.security.consul_sg
  nomad_sg        = module.security.nomad_sg
  bastion_sg      = module.bastion.bastion_sg
  endpoint_sg     = module.security.endpoint_sg
  iam_profile     = module.security.iam_instance_profile_arn_nginx
  instance_type   = module.environment.nginx_instance_type
  domain          = module.globals.domain
  environment     = var.WORKSPACE
}

module "provisioner" {
  source          = "../modules/provisioner"
  src_path        = "../src/provisioner"
  lambda_function = "provisioner"
  subnet_ids      = module.vpc.private_subnets
  security_group  = [module.security.consul_sg, module.security.nomad_sg, module.security.endpoint_sg]
  env             = var.WORKSPACE
}

module "eliza-apigateway" {
  source          = "../modules/eliza-apigateway"
  env             = var.WORKSPACE
}

module "ecr" {
  source = "../modules/ecr"
  env    = var.WORKSPACE
  repositories = module.globals.git_repositories
}

# module "docker" {
#   source          = "../modules/docker"
#   vpc_id          = module.vpc.vpc_id
#   ssh_key_name    = module.security.ssh_key_name
#   public_subnets  = module.vpc.public_subnets
#   private_subnets = module.vpc.private_subnets
#   route53_zone_id = module.globals.route53_zone_id
#   consul_sg       = module.security.consul_sg
#   nomad_sg        = module.security.nomad_sg
#   bastion_sg      = module.bastion.bastion_sg
#   iam_profile     = module.security.iam_instance_profile_arn_docker
#   instance_type   = module.environment.docker_instance_type
#   domain          = module.globals.domain
#   environment     = var.WORKSPACE
# }

# module "rds_mysql" {
#   source = "../modules/rds"
#   environment = var.WORKSPACE
#   active = true
#   database_name = "mysql"
#   rds_config = ({
#     snapshot_id = var.WORKSPACE == "prod1" ? "production-final" : "staging-final"
#     engine = "mysql"
#     engine_version = "8.0.35"
#     parameter_group_name = "default.mysql8.0"
#     enabled_cloudwatch_logs_exports = []
#     allocated_storage = var.WORKSPACE == "prod1" ? 100 : 20
#     instance_class = "db.t3.micro"
#   })
#   nomad_security_group = module.docker.docker_sg
#   bastion_security_group = module.bastion.bastion_sg
#   vpc_id = module.vpc.vpc_id
#   private_subnet_ids = module.vpc.private_subnets
#   rds_username = var.WORKSPACE == "prod1" ? "root" : "admin"
#   rds_password = "Pr1sm!"
# }

module "rds_postgres" {
  source = "../modules/rds"
  environment = var.WORKSPACE
  active = true
  database_name = "eliza"
  rds_config = ({
    snapshot_id = "${var.WORKSPACE}-eliza-final"
    engine = "postgres"
    engine_version = "16.8"
    parameter_group_name = "default.postgres16"
    enabled_cloudwatch_logs_exports = []
    allocated_storage = 40
    instance_class = "db.t3.micro"
  })
  nomad_security_group = module.security.nomad_sg
  bastion_security_group = module.bastion.bastion_sg
  vpc_id = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets
  rds_username = "eliza"
  rds_password = "El1z4Pr0xy!"
  latest_snapshot = false
  named_snapshot = false
}