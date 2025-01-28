#!/bin/sh

ENV=$1

if [ -z "$ENV" ]; then
  echo "Usage: "
  echo ""
  echo "$ $0 <env>"
  echo ""
  exit 1
fi

cd $(dirname $0)/../plays/base/files/nomad/

cfssl print-defaults csr | cfssl gencert -initca - | cfssljson -bare $ENV-ca

#../../../../bin/rotate-nomad-certs.sh $ENV

