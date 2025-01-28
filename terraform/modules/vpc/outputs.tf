output "vpc_id" {
  description = "Id of the vpc"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "azs" {
  description = "List of Availability Zones"
  value       = module.vpc.azs
}
