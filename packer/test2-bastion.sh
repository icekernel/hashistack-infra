#!/bin/sh

packer build -var-file="bastion.pkrvars.hcl" -var-file="env-test2.pkrvars.hcl" base.pkr.hcl
