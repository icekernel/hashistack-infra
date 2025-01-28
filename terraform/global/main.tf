
module "dns" {
  source          = "../modules/dns"
  route53_zone_id = module.globals.route53_zone_id
}

# services

module "eliza" {
  source          = "../modules/eliza"
}

# end services
