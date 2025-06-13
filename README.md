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
