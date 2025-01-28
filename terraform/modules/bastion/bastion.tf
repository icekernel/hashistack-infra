locals {
  role          = "bastion"
  instance_name = "${var.environment}-bastion"
}

resource "aws_elb" "bastion" {
  name            = local.instance_name
  subnets         = var.public_subnets
  security_groups = [aws_security_group.bastion.id]

  listener {
    instance_port     = 22
    instance_protocol = "tcp"
    lb_port           = 22
    lb_protocol       = "tcp"
  }

}

resource "aws_security_group" "bastion" {
  name        = local.instance_name
  description = "Allow only inbound ssh traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
}

data "template_file" "cloud_config_bastion" {
  template = file("${path.root}/../templates/cloud-config.tpl")
  vars = {
    ROLE        = local.role
    ENVIRONMENT = var.environment
  }
}

resource "aws_launch_template" "bastion" {
  name_prefix   = "${local.instance_name}-"
  image_id      = data.aws_ami.bastion.id
  instance_type = var.instance_type
  key_name      = var.ssh_key_name
  iam_instance_profile {
    name = var.iam_profile
  }
  vpc_security_group_ids = [
    aws_security_group.bastion.id,
    var.consul_sg,
    var.nomad_sg,
  ]
  user_data = base64encode(data.template_file.cloud_config_bastion.rendered)
  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }
  update_default_version = true
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      delete_on_termination = true
    }
  }
}

resource "aws_autoscaling_group" "bastion" {
  # availability_zones        = module.vpc.azs
  name                      = local.instance_name
  max_size                  = 1
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 1
  force_delete              = false
  termination_policies      = ["OldestInstance"]
  vpc_zone_identifier       = var.private_subnets
  wait_for_capacity_timeout = 0

  launch_template {
    id      = aws_launch_template.bastion.id
    version = "$Latest"
  }

  load_balancers = [
    aws_elb.bastion.name,
  ]

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]

  lifecycle {
    create_before_destroy = false
  }

  tag {
    key                 = "Name"
    value               = local.instance_name
    propagate_at_launch = true
  }

  tag {
    key                 = "Role"
    value               = local.role
    propagate_at_launch = true
  }

  tag {
    key                 = "ConsulServer"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Terraform"
    value               = "Use-Prism/eliza-infra"
    propagate_at_launch = true
  }
}

resource "aws_route53_record" "bastion" {
  name    = local.instance_name
  type    = "CNAME"
  ttl     = "300"
  zone_id = var.route53_zone_id
  records = [aws_elb.bastion.dns_name]
}
