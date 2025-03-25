locals {

  bastion_instance_type = {
    test1   = "t2.micro"
    test2   = "t2.micro"
    prod1   = "t2.micro"
    prod2   = "t2.micro"
    global  = null
  }
  eliza_instance_type = {
    test1   = "t3.small"
    test2   = "t3.small"
    prod1   = "t3.small"
    prod2   = "t3.small"
    global  = null
  }
  nginx_instance_type = {
    test1   = "t3.small"
    test2   = "t3.small"
    prod1   = "t3.small"
    prod2   = "t3.small"
    global  = null
  }
  docker_instance_type = {
    test1   = "r5.large"
    test2   = "r5.large"
    prod1   = "r5.large"
    prod2   = "r5.large"
    global  = null
  }

  aws_region = {
    test1   = "eu-central-1"
    test2   = "eu-central-1"
    prod1   = "eu-central-1"
    prod2   = "eu-central-1"
    global  = "eu-central-1"
  }
}
