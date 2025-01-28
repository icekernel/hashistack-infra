#!/bin/sh

ENV=$1
DC=$2
DOMAIN=$3

VALID_DAYS=3650

if [ -z "$ENV" ]; then
  echo "Usage: "
  echo ""
  echo "$ $0 <env> <?dc='eu-central-1'> <?domain='consul'>"
  echo ""
  exit 1
fi
if [ -z "$DC" ]; then
  DC="eu-central-1"
  echo "Using default DC: $DC"
fi
if [ -z "$DOMAIN" ]; then
  DOMAIN="consul"
  echo "Using default DOMAIN: $DOMAIN"
fi

cd $(dirname $0)/../plays/base/files/consul/

# cleanup old simlinks
rm -f $DC-$ENV-client-$DOMAIN-latest.pem
rm -f $DC-$ENV-client-$DOMAIN-latest-key.pem
rm -f $DC-$ENV-server-$DOMAIN-latest.pem
rm -f $DC-$ENV-server-$DOMAIN-latest-key.pem

consul tls cert create -client -dc=$DC-$ENV -days=$VALID_DAYS -ca ${ENV}-${DOMAIN}-agent-ca.pem -key ${ENV}-${DOMAIN}-agent-ca-key.pem
consul tls cert create -server -dc=$DC-$ENV -days=$VALID_DAYS -ca ${ENV}-${DOMAIN}-agent-ca.pem -key ${ENV}-${DOMAIN}-agent-ca-key.pem

# shame the `?` seems to only work on single digits... after 10 certs, rotate
# ca? must find a better way to expand this or get lastest
latest_client_cert=$(ls -t $DC-$ENV-client-$DOMAIN-?.pem | head -1)
latest_client_key=$(ls -t $DC-$ENV-client-$DOMAIN-?-key.pem | head -1)
latest_server_cert=$(ls -t $DC-$ENV-server-$DOMAIN-?.pem | head -1)
latest_server_key=$(ls -t $DC-$ENV-server-$DOMAIN-?-key.pem | head -1)

echo "Linking $latest_client_cert to $DC-$ENV-client-$DOMAIN-latest.pem"
ln -sf $DC-$ENV-client-$DOMAIN-0.pem $DC-$ENV-client-$DOMAIN-latest.pem
echo "Linking $latest_client_key to $DC-$ENV-client-$DOMAIN-latest-key.pem"
ln -sf $latest_client_key $DC-$ENV-client-$DOMAIN-latest-key.pem
echo "Linking $latest_server_cert to $DC-$ENV-server-$DOMAIN-latest.pem"
ln -sf $latest_server_cert $DC-$ENV-server-$DOMAIN-latest.pem
echo "Linking $latest_server_key to $DC-$ENV-server-$DOMAIN-latest-key.pem"
ln -sf $latest_server_key $DC-$ENV-server-$DOMAIN-latest-key.pem
