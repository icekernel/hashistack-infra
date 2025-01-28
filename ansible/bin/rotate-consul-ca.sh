#!/bin/sh

ENV=$1
DC=$2
DOMAIN=consul

VALID_DAYS=3650

if [ -z "$ENV" ]; then
  echo "Usage: "
  echo ""
  echo "$ $0 <env> <?dc='eu-central-1'>"
  echo ""
  exit 1
fi
if [ -z "$DC" ]; then
  DC="ca-central-1"
  echo "Using default DC: $DC"
fi

cd $(dirname $0)/../plays/base/files/consul/

rm $ENV-$DOMAIN-agent-ca.pem
rm $ENV-$DOMAIN-agent-ca-key.pem
rm $DC-$ENV-*

consul tls ca create -days=$VALID_DAYS -domain=$DOMAIN
consul tls ca create -days=$VALID_DAYS -domain=$DOMAIN

mv ${DOMAIN}-agent-ca.pem ${ENV}-${DOMAIN}-agent-ca.pem
mv ${DOMAIN}-agent-ca-key.pem ${ENV}-${DOMAIN}-agent-ca-key.pem

../../../../bin/rotate-consul-certs.sh $ENV $DC $DOMAIN

