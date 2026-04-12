#!/bin/sh
# Healthcheck script for Coolify MCP Server
# Verifies that the supergateway SSE endpoint is responding

set -e

PORT="${MCP_PORT:-8000}"

wget --no-verbose --tries=1 --spider "http://localhost:${PORT}/sse" || exit 1
