# syntax=docker/dockerfile:1

FROM node:24-alpine

ARG PORT=3000
ARG NAMESPACE
ARG VERSION

LABEL org.opencontainers.image.source=https://github.com/${NAMESPACE}/folio
LABEL org.opencontainers.image.version=${VERSION}
LABEL org.opencontainers.image.license=MIT

WORKDIR /app
USER node

COPY --chown=node:node folio/package*.json ./
COPY --chown=node:node folio/build ./build
COPY --chown=node:node folio/static ./static

EXPOSE ${PORT:-3000}

CMD ["node", "build", "--port", "${PORT}"]
