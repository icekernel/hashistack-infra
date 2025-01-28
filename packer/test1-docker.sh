#!/bin/sh

packer build -var-file="env-test1.pkrvars.hcl" -var-file="docker.pkrvars.hcl" base.pkr.hcl
