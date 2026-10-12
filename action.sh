#!/bin/bash

set -euxo pipefail

request() {
    if ! resp="$(curl --silent --fail-with-body "$@")"
    then
        curl_exit_code="$?"
        echo "$resp" >&2
        exit "$curl_exit_code"
    fi
    echo "$resp"
}

if [[ ! -v ACTIONS_ID_TOKEN_REQUEST_TOKEN ]]
then
    message="No \$ACTIONS_ID_TOKEN_REQUEST_TOKEN is set. Does this job have the \`id-token: write\` permission necessary to get a Cloudsmith token?"
    echo "$message" >&2
    echo "::error title=Missing \`id-token: write\` permission?::${message}"
    exit 1
fi

CLOUDSMITH_ACCOUNT=${CLOUDSMITH_ACCOUNT:-$GITHUB_REPOSITORY_OWNER}
echo "Retrieving actions OIDC token"
id_token=$(request -H "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" "$ACTIONS_ID_TOKEN_REQUEST_URL&audience=api://AzureADTokenExchange" | jq -r '.value')
echo "Retrieving Cloudsmith token for account: $CLOUDSMITH_ACCOUNT (service account: $SERVICE_SLUG)"
cloudsmith_token=$(request -X POST -H "Content-Type: application/json" -d "{\"oidc_token\":\"$id_token\", \"service_slug\":\"$SERVICE_SLUG\"}" "https://api.cloudsmith.io/openid/$CLOUDSMITH_ACCOUNT/" | jq -r '.token')
echo "value=$cloudsmith_token" >> "$GITHUB_OUTPUT"

file="$(mktemp)"
echo "CLOUDSMITH_TOKEN=$cloudsmith_token" >> "$file"
echo "file=$file" >> "$GITHUB_OUTPUT"
