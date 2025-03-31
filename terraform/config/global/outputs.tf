output "product" {
  value = "eliza"
}

output "aws_region" {
  value = "sa-east-1"
}

output "account_id" {
  value = "711054401116"
}

output "domain" {
  value = "icekernelcloud01.com"
}

output "route53_zone_id" {
  value = "Z0401772240U357QN2G31" # icekernelcloud01.com
}

output "git_repositories" {
  value = {
    "billing" = {
      description = "Billing API"
    }
    "history" = {
      description = "history API"
    }
    "proxy" = {
      description = "proxy API"
    }
    "shop" = {
      description = "Shop API"
    }
  }
}