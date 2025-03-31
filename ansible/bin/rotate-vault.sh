#!/bin/bash

set -euo pipefail

cd $(dirname $0)/../

ENV=${1}
DC=${2:-sa-east-1}
DOMAIN=consul

VALID_DAYS=3650

if [ -z "$ENV" ]; then
  echo "Usage: "
  echo ""
  echo "$ $0 <env> <?dc='sa-east-1'>"
  echo ""
  exit 1
fi

mkdir -p ./plays/base/files/vault
# Paths
CONSUL_CA_CERT="./plays/base/files/consul/${ENV}-${DOMAIN}-agent-ca.pem"
CONSUL_CA_KEY="./plays/base/files/consul/${ENV}-${DOMAIN}-agent-ca-key.pem"
VAULT_SERVER_CERT="./plays/base/files/vault/${ENV}-${DOMAIN}-server.pem"
VAULT_SERVER_KEY="./plays/base/files/vault/${ENV}-${DOMAIN}-server-key.pem"
VAULT_AGENT_CERT="./plays/base/files/vault/${ENV}-${DOMAIN}-agent.pem"
VAULT_AGENT_KEY="./plays/base/files/vault/${ENV}-${DOMAIN}-agent-key.pem"

# Generate Vault server key
openssl genrsa -out "${VAULT_SERVER_KEY}" 2048

# Generate Vault server certificate signing request (CSR)
openssl req -new \
  -key "${VAULT_SERVER_KEY}" \
  -subj "/CN=vault.service.${DOMAIN}" \
  -addext "subjectAltName=DNS:vault.service.${DOMAIN},DNS:localhost" \
  -out vault.csr

# Sign the Vault server certificate using the Consul CA
openssl x509 -req \
  -in vault.csr \
  -CA "${CONSUL_CA_CERT}" \
  -CAkey "${CONSUL_CA_KEY}" \
  -CAcreateserial \
  -out "${VAULT_SERVER_CERT}" \
  -days "${VALID_DAYS}"

echo "Vault server certificate and key generated."

# Generate Vault agent key
openssl genrsa -out "${VAULT_AGENT_KEY}" 2048

# Generate Vault agent certificate signing request (CSR)
openssl req -new \
  -key "${VAULT_AGENT_KEY}" \
  -subj "/CN=vault-agent.service.${DOMAIN}" \
  -addext "subjectAltName=DNS:vault-agent.service.${DOMAIN},DNS:localhost" \
  -out agent.csr

# Sign the Vault agent certificate using the Consul CA
openssl x509 -req \
  -in agent.csr \
  -CA "${CONSUL_CA_CERT}" \
  -CAkey "${CONSUL_CA_KEY}" \
  -CAcreateserial \
  -out "${VAULT_AGENT_CERT}" \
  -days "${VALID_DAYS}"

echo "Vault agent certificate and key generated."

# Clean up the CSR
rm -f vault.csr
rm -f agent.csr
