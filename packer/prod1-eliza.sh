#!/bin/sh

packer build -var-file="env-prod1.pkrvars.hcl" -var-file="eliza.pkrvars.hcl" base.pkr.hcl
