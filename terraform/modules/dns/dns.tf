resource "aws_route53_record" "naked" {
  name    = ""
  type    = "A"
  ttl     = "300"
  zone_id = var.route53_zone_id
  records = ["1.1.1.1"]
}

resource "aws_route53_record" "mail" {
  name    = "mail"
  type    = "A"
  ttl     = "300"
  zone_id = var.route53_zone_id
  records = ["1.1.1.1"]
}

resource "aws_route53_record" "prod-admin" {
  name    = "prod-admin"
  type    = "CNAME"
  ttl     = "300"
  zone_id = var.route53_zone_id
  records = ["somwhere.cloudfront.net"]
}

resource "aws_route53_record" "staging-admin" {
  name    = "staging-admin"
  type    = "CNAME"
  ttl     = "300"
  zone_id = var.route53_zone_id
  records = ["somewhere.cloudfront.net"]
}

resource "aws_route53_record" "www" {
  name    = "www"
  type    = "CNAME"
  ttl     = "300"
  zone_id = var.route53_zone_id
  records = [var.domain]
}

resource "aws_route53_record" "www_admin" {
  name    = "www.admin"
  type    = "CNAME"
  ttl     = "300"
  zone_id = var.route53_zone_id
  records = [var.domain]
}

# resource "aws_route53_record" "google_mx" {
#   name    = ""
#   type    = "MX"
#   ttl     = "300"
#   zone_id = var.route53_zone_id
#   records = [
#     "1 ASPMX.L.GOOGLE.COM",
#     "5 ALT1.ASPMX.L.GOOGLE.COM",
#     "5 ALT2.ASPMX.L.GOOGLE.COM",
#     "10 ALT3.ASPMX.L.GOOGLE.COM",
#     "10 ALT5.ASPMX.L.GOOGLE.COM",
#   ]
# }

resource "aws_route53_record" "txt" {
  name    = ""
  type    = "TXT"
  ttl     = "300"
  zone_id = var.route53_zone_id
  records = [
    # "v=spf1 include:spf.mandrillapp.com ?all",
    "google-site-verification=generated-code",
  ]
}

# resource "aws_route53_record" "mandrill_domainkey" {
#   name    = "mandrill._domainkey"
#   type    = "TXT"
#   ttl     = "300"
#   zone_id = var.route53_zone_id
#   records = [
#     "v=DKIM1; k=rsa; p=need_key;"
#   ]
# }

resource "aws_route53_record" "production_eliza" {
  name    = "app"
  type    = "CNAME"
  ttl     = "60"
  zone_id = var.route53_zone_id
  records = ["prod1-eliza.${var.domain}"]
}
