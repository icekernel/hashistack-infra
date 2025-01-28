#!/bin/sh

ENV=$1
DOMAIN=$2

VALID_DAYS=3650

if [ -z "$ENV" ]; then
  echo "Usage: "
  echo ""
  echo "$ $0 <env> <?domain='consul'>"
  echo ""
  exit 1
fi
if [ -z "$DOMAIN" ]; then
  DOMAIN="consul"
  echo "Using default DOMAIN: $DOMAIN"
fi

cd $(dirname $0)/../plays/base/files/consul/

echo "old $ENV-$DOMAIN-gossip.key"
cat $ENV-$DOMAIN-gossip.key
rm -f $ENV-$DOMAIN-gossip.key
key=$(consul keygen)
echo "new $ENV-$DOMAIN-gossip.key"
echo $key | tee $ENV-$DOMAIN-gossip.key
