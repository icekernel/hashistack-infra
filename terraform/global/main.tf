
module "dns" {
  source          = "../modules/dns"
  route53_zone_id = module.globals.route53_zone_id
}

# end services
