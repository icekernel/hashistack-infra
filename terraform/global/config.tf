########## Customize to change region and domain ##########

module "globals" {
  source = "../config/global"
}

module "environment" {
  source      = "../config/environment"
  environment = var.WORKSPACE
}
