# Same pinned Linux base as the current sfx-platform Docker build.
FROM node:24.20.0-bookworm-slim@sha256:6642ef280aebc09c4541bee0b15c9f89f0f3f3c247ddee79ae1d37eddfdcbbaa
WORKDIR /proof
COPY package.json package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts --no-audit --no-fund && npm cache clean --force
COPY load-memory-scenario.mjs run.mjs cases.json ./
COPY plans ./plans
USER node
CMD ["node", "--experimental-vm-modules", "run.mjs"]
