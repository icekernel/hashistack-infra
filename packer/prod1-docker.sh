#!/bin/sh

packer build -on-error=ask -var-file="env-prod1.pkrvars.hcl" -var-file="docker.pkrvars.hcl" base.pkr.hcl
