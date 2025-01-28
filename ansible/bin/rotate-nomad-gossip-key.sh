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

echo "old $ENV-gossip.key"
cat $ENV-gossip.key
rm -f $ENV-gossip.key
key=$(nomad operator gossip keyring generate)
echo "new $ENV-gossip.key"
echo $key | tee $ENV-gossip.key
