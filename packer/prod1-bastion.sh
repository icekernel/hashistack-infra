#!/bin/sh

packer build -on-error=ask -var-file="env-prod1.pkrvars.hcl" -var-file="bastion.pkrvars.hcl" base.pkr.hcl
