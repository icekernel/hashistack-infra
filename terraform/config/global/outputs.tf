output "product" {
  value = "prism1"
}

output "aws_region" {
  value = "eu-central-1"
}

output "account_id" {
  value = "686255952373"
}

output "domain" {
  value = "prism1.click"
}

output "route53_zone_id" {
  value = "Z00401101Y262GI1S5IJ9" # prism1.click
}

output "git_repositories" {
  value = {
    "billing" = {
      description = "Eliza Billing API"
    }
    "history" = {
      description = "Eliza history API"
    }
    "proxy" = {
      description = "Eliza proxy API"
    }
    "shop" = {
      description = "Eliza shop API"
    }
  }
}