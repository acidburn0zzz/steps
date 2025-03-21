#!/usr/bin/env bash
set -e

msg() { echo -e "\e[32mINFO [$(date +%F_%H-%M-%S)] ---> $1\e[0m"; }
yellow() { echo -e "\e[33m$1\e[0m"; }
err() { echo -e "\e[31mERR [$(date +%F_%H-%M-%S)] ---> $1\e[0m" ; exit 1; }

REQUIRED_VARS=(
    VAULT_ADDR
    VAULT_PATH
    VAULT_AUTH_TOKEN
    VAULT_CLIENT_CERT_BASE64
    VAULT_CLIENT_KEY_BASE64
)

# There might be values for cf empty vars, like ${{VAR}} substituted like this into
# the script. We want them to be really empty
for var in ${REQUIRED_VARS[*]}; do
    if ( echo "${!var}" | grep '${{' &>/dev/null ); then eval $var=""; fi
done

#### Checking
[ -z "$VAULT_ADDR" ] && err "Need to set VAULT_ADDR"
[ -z "$VAULT_PATH" ] && err "Need to set VAULT_PATH"
[ -z "$VAULT_AUTH_TOKEN" ] && err "Need to set VAULT_AUTH_TOKEN"

if [ ! -z "$VAULT_CLIENT_CERT_BASE64" ]; then
   echo $VAULT_CLIENT_CERT_BASE64 | base64 -d > /client.cert.pem
   echo $VAULT_CLIENT_KEY_BASE64 | base64 -d > /client.key.pem
   chmod 700 /client.*
   export VAULT_CLIENT_CERT="/client.cert.pem"
   export VAULT_CLIENT_KEY="/client.key.pem"
fi

echo "Vault URL is: $VAULT_ADDR"

msg "Authenticating Vault"

vault login $VAULT_AUTH_TOKEN  >/dev/null

if [ $? == 0 ]; then
  msg "You are successfully authenticated"
fi

export VAULT_FORMAT="json"
msg "Reading provided path"

for s in $(vault kv get $VAULT_PATH | jq -c '.data.data' | jq -r "to_entries|map(\"\(.key)=\(.value|tostring)\")|.[]" ); do
    echo $s >> $CF_VOLUME_PATH/env_vars_to_export
done


