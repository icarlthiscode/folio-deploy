# folio-deploy
These automation tools contain the code and configuration files for building and
deploying the [`folio`](https://github.com/icarlthiscode/folio) application. The
application is built and bundled using the *SvelteKit* *Node.js" adapter and the
output is containerized into a *Docker* image.

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
The `folio` application can be deployed to a locally running Docker engine
using the `deploy` script. This script will pull the latest image from the local
Docker registry or the GitHub Packages registry and run it in a container on
port `3000`.
```bash
deploy
```

To cleanup the running container, run the `destroy` script, which will stop and
remove the container running the `folio` application.
```bash
destroy
```
