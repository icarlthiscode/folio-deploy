# folio-deploy
These automation tools contain the code and configuration files for building and
deploying the [`folio`](https://github.com/icarlthiscode/folio) application. The
application is built and bundled using the *SvelteKit* *Node.js" adapter and the
output is containerized into a *Docker* image.

## Validation
Before building the application, you can validate the application code using
the `validate` script. This script will run all tests defined in the `folio`
application.
```bash
validate
```

## Build & Containerization
To build and containerize a deployable application, run the provided
containerization script. If successful, the script resulting image will be
tagged as `folio:latest` and pushed to the local Docker registry.
```bash
containerize
```

To push to the GitHub Packages registry, option `--push` can be used. To push to
the registry, a GitHub namespace must passed as an argument to the script or be
set as an environment variable `GITHUB_NAMESPACE`.
```bash
containerize --push --namespace <GITHUB_NAMESPACE>
```

## Deployment
The `folio` application can be deployed to a remote server or a local Docker
instance for development and testing using the `deploy` script. To see the full
list of options, run the script with the `--help` option.
```bash
deploy --help
```

### Remote Deployment
By default, the script will attempt to deploy the application to a remote
server by applying a Terraform plan. Appropriate configuration must be provided
by ether setting the required environment variables, adding a `.env` file to
the root of the repository, or passing the required variables as arguments to
the script. To deploy to a remote server, the script requires specifying:
- the application GitHub namespace
    (the account hosting the application package),
- the domain (or subdomain) where the application will be deployed,
- the Cloudflare DNS zone of the domain records,
- the public key file to register on the remote server,
- a Cloudflare API token,
- a DigitalOcean API token.
````bash
deploy \
    --namespace <GITHUB_NAMESPACE> \
    --domain <DOMAIN> \
    --dns-zone <CF_DNS_ZONE> \
    --public-key <PUBLIC_KEY_FILE> \
    --cf-token <CF_TOKEN> \
    --do-token <DO_TOKEN>
````

The provided Cloudflare API token must have the scopes, for all applicable
zones:
- `DNS:Edit`.

The provided DigitalOcean API token must have the scopes:
- `droplet:create`,
- `droplet:read`,
- `droplet:update`,
- `droplet:delete`.

To automatically apply the Terraform plan without interaction, you can
add the `--approve` option.
```bash
deploy --approve
```

Remote deployment requires that the requested `folio` Docker image version is
available on GitHub Packages.

### Local Deployment
If the `--local` option is used, the script will attempt to run the application
on a local container, exposing port 3000. The latest image will be pull from the
local Docker registry, or if unavailable, the GitHub Packages registry.
port `3000`.
```bash
deploy --local
```

## Cleanup
To tear down the application, either to cleanup local development or destroy the
remote resources, the `destroy` script can be executed. A usage description
can be obtained by running the script with the `--help` option.
```bash
destroy --help
```

### Remote Cleanup
To destroy the remote resources, the script requires the same parameters as the
`deploy` script. The parameters are required to ensure the correct resources
are identified and destroyed by Terraform.
```bash
destroy \
    --namespace <GITHUB_NAMESPACE> \
    --domain <DOMAIN> \
    --dns-zone <CF_DNS_ZONE> \
    --public-key <PUBLIC_KEY_FILE> \
    --cf-token <CF_TOKEN> \
    --do-token <DO_TOKEN>
```

To automatically apply approve the destruction of all resources, add the
`--approve` option.
```bash
destroy --approve
```

### Local Cleanup
To clean up the local resources, the script will attempt to stop and remove the
`folio` container, and remove the local Docker image.
```bash
destroy --local
```
