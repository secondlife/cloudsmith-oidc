#!/bin/bash

set -eu

# https://superuser.com/a/1641410
curlf() {
    output_file=$(mktemp)
    code=$(curl --silent --output $output_file --write-out "%{http_code}" "$@")
    if [[ ${code} -lt 200 || ${code} -gt 299 ]]; then
        >&2 cat $output_file
        return 22
    fi
    cat $output_file
    rm $output_file
}

request() {
    set +e
    resp="$(curlf "$@")"
    rc=$?
    set -e
    # shellcheck disable=SC2181
    if [ $rc -ne 0 ]; then
        echo "$resp" >> /dev/stderr
        exit 1
    fi
    echo "$resp"
}

if [[ ! -v ACTIONS_ID_TOKEN_REQUEST_TOKEN ]]
then
    message='No $ACTIONS_ID_TOKEN_REQUEST_TOKEN is set. Does this job have the `id-token: write` permission necessary to get a Cloudsmith token?'
    echo "$message" >&2
    echo '::error title=Missing `id-token: write` permission?::'"$message"
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
