#!/usr/bin/env bash

set -eu

request() {
  set +e
  resp="$(curl -s --fail-with-body "$@")"
  rc=$?
  set -e
  # shellcheck disable=SC2181
  if [ $rc -ne 0 ]; then
    echo "$resp" >> /dev/stderr
    exit 1
  fi
  echo "$resp"
}

CLOUDSMITH_ACCOUNT=${CLOUDSMITH_ACCOUNT:-$GITHUB_REPOSITORY_OWNER}
echo "Retrieving actions OIDC token"
id_token=$(request -H "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" "$ACTIONS_ID_TOKEN_REQUEST_URL&audience=api://AzureADTokenExchange" | jq -r '.value')
echo "Retrieving Cloudsmith token for account: $CLOUDSMITH_ACCOUNT (service account: $SERVICE_SLUG)"
cloudsmith_token=$(request -X POST -H "Content-Type: application/json" -d "{\"oidc_token\":\"$id_token\", \"service_slug\":\"$SERVICE_SLUG\"}" "https://api.cloudsmith.io/openid/$CLOUDSMITH_ACCOUNT/" | jq -r '.token')
echo "value=$cloudsmith_token" >> "$GITHUB_OUTPUT"
