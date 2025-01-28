#!/bin/sh

terraform taint module.backend.aws_launch_configuration.eliza
terraform taint module.backend.aws_autoscaling_group.eliza
