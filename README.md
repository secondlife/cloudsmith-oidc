# cloudsmith-oidc

A basic action to retrieve a [Cloudsmith OIDC token][oidc].

Example:
```yaml
permissions:
  id-token: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: secondlife/cloudsmith-oidc@v1
        id: cloudsmith-oidc
        with:
          # Your Cloudsmith organization name
          account: account-name
          # Your OIDC service account slug ("service identifier")
          service: service-XXXX
      - name: Push
        id: push
        uses: cloudsmith-io/action@master
        with:
          api-key: ${{ steps.cloudsmith-oidc.outputs.token }}
          # ...
```

Either [jq] or Python is required. To use in a [containerized job] or on a custom runner image, ensure Python is available or install jq.

[containerized job]: https://docs.github.com/en/actions/how-tos/write-workflows/choose-where-workflows-run/run-jobs-in-a-container
[jq]: https://jqlang.org
[oidc]: https://help.cloudsmith.io/docs/openid-connect
