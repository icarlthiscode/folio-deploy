# syntax=docker/dockerfile:1

FROM node:24-alpine

ARG PORT=3000

WORKDIR /app
USER node

COPY --chown=node:node folio/package*.json ./
COPY --chown=node:node folio/build ./build
COPY --chown=node:node folio/static ./static

EXPOSE ${PORT:-3000}

CMD ["node", "build", "--port", "${PORT}"]
