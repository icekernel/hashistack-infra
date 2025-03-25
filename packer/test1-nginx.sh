#!/bin/sh

packer build -on-error=ask -var-file="env-test1.pkrvars.hcl" -var-file="nginx.pkrvars.hcl" base.pkr.hcl
