locals {
  role          = "nginx"
  instance_name = "${var.environment}-nginx"
}

resource "aws_security_group" "nginx" {
  name        = local.instance_name
  description = "Allow inbound nginx traffic and mgmt ssh"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [var.bastion_sg]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [var.bastion_sg]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    "Name" = "${local.instance_name}-80a-443a-22b-0x"
  }
}

data "template_file" "cloud_config_nginx" {
  template = file("${path.root}/../templates/cloud-config.tpl")
  vars = {
    ROLE        = local.role
    ENVIRONMENT = var.environment
  }
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0.1"

  domain_name = "${local.instance_name}.${var.domain}"
  zone_id     = data.aws_route53_zone.zone.id

  wait_for_validation = true

  subject_alternative_names = [
    "*.${var.domain}",
  ]

  tags = {
    Name = "${local.instance_name}.${var.domain}"
  }

}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 6.5.1"

  # Autoscaling group
  name = local.instance_name

  security_groups = [
    aws_security_group.nginx.id,
    var.consul_sg,
    var.nomad_sg,
    var.endpoint_sg,
  ]

  min_size                  = 1
  max_size                  = 3
  desired_capacity          = 1
  wait_for_capacity_timeout = 0

  # disabled health_check_type because we are not in high-availability mode yet
  # health_check_type         = "ELB"

  vpc_zone_identifier = var.private_subnets

  # Launch template
  launch_template_name        = local.instance_name
  launch_template_description = "nginx launch template"
  update_default_version      = true

  image_id      = data.aws_ami.nginx.id
  instance_type = var.instance_type
  key_name      = var.ssh_key_name

  # ebs_optimized = true   # if high disk read/write needs, set true

  user_data = base64encode(data.template_file.cloud_config_nginx.rendered)

  # IAM role & instance profile
  create_iam_instance_profile = false
  iam_instance_profile_arn    = var.iam_profile

  target_group_arns = module.alb.target_group_arns

  instance_refresh = {}

  block_device_mappings = [
    {
      device_name = "/dev/sda1"
      ebs = {
        delete_on_termination = true
        volume_size           = 32
      }
    }
  ]

  metadata_options = {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  tag_specifications = [
    {
      resource_type = "instance"
      tags          = { WhatAmI = "Instance" }
    },
    {
      resource_type = "volume"
      tags          = { WhatAmI = "Volume" }
    }
  ]

  tags = {
    Environment = var.environment
    Role        = local.role
    Terraform   = "Use-Prism/eliza-infra"
  }
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 7.0"

  name = local.instance_name

  load_balancer_type = "application"

  vpc_id  = var.vpc_id
  subnets = var.public_subnets
  security_groups = [
    aws_security_group.nginx.id,
  ]

  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = module.acm.acm_certificate_arn
      target_group_index = 0
    }
  ]

  target_groups = [
    {
      name             = local.instance_name
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      health_check = {
        path                = "/ping" # traefik health check
        interval            = 10
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
      }
    }
  ]

  # access_logs = {
  #   bucket = "${var.logs_bucket}"
  # }

  tags = {
    Environment = var.environment
    Role        = local.role
    Terraform   = "Use-Prism/eliza-infra"
  }
}

resource "aws_route53_record" "nginx" {
  zone_id = var.route53_zone_id
  name    = local.instance_name
  type    = "A"
  alias {
    name                   = module.alb.lb_dns_name
    zone_id                = module.alb.lb_zone_id
    evaluate_target_health = true
  }
}
