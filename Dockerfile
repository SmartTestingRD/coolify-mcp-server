# =============================================================================
# Coolify MCP Server — Production Dockerfile
# Wraps the stdio MCP server with supergateway to expose HTTP/SSE endpoint
# =============================================================================

# Stage 1: Build TypeScript
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY tsconfig.json ./
COPY src ./src

RUN npm run build

# Stage 2: Production image
FROM node:20-alpine

WORKDIR /app

# Create non-root user BEFORE copying files
RUN addgroup -S mcpuser && adduser -S mcpuser -G mcpuser

# Copy package files and install production deps + supergateway locally
COPY --chown=mcpuser:mcpuser package*.json ./
RUN npm ci --omit=dev --ignore-scripts && \
    npm install --save supergateway && \
    npm cache clean --force

# Copy compiled output from builder
COPY --chown=mcpuser:mcpuser --from=builder /app/dist ./dist

# Switch to non-root user
USER mcpuser

# Environment variables (must be provided at runtime)
ENV COOLIFY_BASE_URL=""
ENV COOLIFY_ACCESS_TOKEN=""
ENV MCP_PORT=8000
ENV MCP_AUTH_TOKEN=""
ENV NODE_ENV=production

EXPOSE 8000

# Healthcheck: use dedicated /health endpoint from supergateway
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD wget -q --spider --timeout=3 http://localhost:${MCP_PORT:-8000}/health 2>/dev/null || exit 1

# Start supergateway wrapping the stdio MCP server (local install)
CMD ["sh", "-c", \
  "./node_modules/.bin/supergateway \
  --stdio 'node dist/index.js' \
  --port ${MCP_PORT:-8000} \
  --outputTransport http \
  --cors \
  --healthEndpoint /health \
  --oauth2Bearer ${MCP_AUTH_TOKEN:-}"]
