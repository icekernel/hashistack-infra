#!/bin/sh

terraform taint module.bastion.aws_launch_configuration.bastion
terraform taint module.bastion.aws_autoscaling_group.bastion
