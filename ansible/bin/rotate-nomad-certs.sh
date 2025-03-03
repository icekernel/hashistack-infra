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

# echo '{}' | cfssl gencert -profile=server -ca=$ENV-ca.pem -ca-key=$ENV-ca-key.pem -config="$current_dir/cfssl.json" \
#   -hostname="nomad.service.consul,server.global.nomad,localhost,127.0.0.1" - | cfssljson -bare $ENV-server
# echo '{}' | cfssl gencert -profile=client -ca=$ENV-ca.pem -ca-key=$ENV-ca-key.pem -config="$current_dir/cfssl.json" \
#   -hostname="client.global.nomad,localhost,127.0.0.1" - | cfssljson -bare $ENV-client
# echo '{}' | cfssl gencert -ca=$ENV-ca.pem -ca-key=$ENV-ca-key.pem -profile=client \
#   - | cfssljson -bare $ENV-cli

nomad tls cert create \
  -server \
  -region=global \
  -ca=$ENV-ca.pem \
  -key=$ENV-ca-key.pem \
  -additional-dnsname=nomad.service.consul \
  -additional-dnsname=server.global.nomad \
  -additional-dnsname=localhost
mv global-server-nomad-key.pem $ENV-server-key.pem
mv global-server-nomad.pem $ENV-server.pem

nomad tls cert create \
  -ca=$ENV-ca.pem \
  -key=$ENV-ca-key.pem \
  -client
mv global-client-nomad-key.pem $ENV-client-key.pem
mv global-client-nomad.pem $ENV-client.pem

nomad tls cert create \
  -ca=$ENV-ca.pem \
  -key=$ENV-ca-key.pem \
  -cli
mv global-cli-nomad-key.pem $ENV-cli-key.pem
mv global-cli-nomad.pem $ENV-cli.pem
