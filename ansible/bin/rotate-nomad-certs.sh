#!/bin/sh

ENV=$1

if [ -z "$ENV" ]; then
  echo "Usage: "
  echo ""
  echo "$ $0 <env>"
  echo ""
  exit 1
fi

current_dir=$(pwd)

cd $(dirname $0)/../plays/base/files/nomad/

echo '{}' | cfssl gencert -profile=server -ca=$ENV-ca.pem -ca-key=$ENV-ca-key.pem -config="$current_dir/cfssl.json" \
  -hostname="nomad.service.consul,server.global.nomad,localhost,127.0.0.1" - | cfssljson -bare $ENV-server
echo '{}' | cfssl gencert -profile=client -ca=$ENV-ca.pem -ca-key=$ENV-ca-key.pem -config="$current_dir/cfssl.json" \
  -hostname="client.global.nomad,localhost,127.0.0.1" - | cfssljson -bare $ENV-client
echo '{}' | cfssl gencert -ca=$ENV-ca.pem -ca-key=$ENV-ca-key.pem -profile=client \
  - | cfssljson -bare $ENV-cli
