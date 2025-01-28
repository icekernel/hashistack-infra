#!/bin/sh

packer build -var-file="bastion.pkrvars.hcl" -var-file="env-test1.pkrvars.hcl" base.pkr.hcl
