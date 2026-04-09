# ─────────────────────────────────────────
# Stage 1: dev
# Used locally for development with hot reload
# ─────────────────────────────────────────
FROM node:20-alpine AS dev

WORKDIR /app

# Copy dependency manifests first (layer cache optimization)
COPY package*.json ./
RUN npm install

# Copy source code
COPY . .

EXPOSE 3000
CMD ["npx", "nodemon", "index.js"]


# ─────────────────────────────────────────
# Stage 2: prod
# Minimal image used by ECS Fargate
# ─────────────────────────────────────────
FROM node:20-alpine AS prod

WORKDIR /app

# Copy dependency manifests and install production deps only
COPY package*.json ./
RUN npm install --omit=dev

# Copy source code
COPY . .

EXPOSE 3000
CMD ["node", "index.js"]
