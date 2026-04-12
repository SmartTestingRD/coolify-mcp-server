# Coolify MCP Server — Docker Deployment Guide

This guide explains how to build, run, and deploy the Coolify MCP server as a containerized HTTP/SSE service.

## Architecture

The MCP server natively uses **stdio** transport. To expose it over HTTP, the Docker image uses [supergateway](https://github.com/supercorp-ai/supergateway) to wrap the stdio process and expose an **SSE endpoint** on port 8000.

```text
Client (Antigravity/HTTP) → :8000/sse → supergateway → stdio → coolify-mcp
```

## Prerequisites

- Docker 20+ installed
- A running Coolify instance with API access enabled
- A Coolify API access token

## 1. Get Your Coolify API Token

1. Open your Coolify dashboard
2. Go to **Settings → API**
3. Click **Generate Token**
4. Copy the token — you'll need it as `COOLIFY_ACCESS_TOKEN`

## 2. Configure Environment Variables

```bash
cp .env.example .env
```

Edit `.env` and set:

```env
COOLIFY_BASE_URL=https://coolify.yourdomain.com
COOLIFY_ACCESS_TOKEN=your-api-token-here
```

| Variable               | Required | Default                 | Description                  |
| ---------------------- | -------- | ----------------------- | ---------------------------- |
| `COOLIFY_BASE_URL`     | Yes      | `http://localhost:3000` | Your Coolify instance URL    |
| `COOLIFY_ACCESS_TOKEN` | Yes      | —                       | API token from Coolify       |
| `MCP_PORT`             | No       | `8000`                  | Port for the HTTP/SSE server |
| `NODE_ENV`             | No       | `production`            | Node environment             |

## 3. Build the Docker Image

```bash
docker build -t coolify-mcp:latest .
```

## 4. Run with Docker Compose (recommended)

```bash
docker compose up -d
```

Verify it's running:

```bash
docker compose ps
docker compose logs -f coolify-mcp
```

## 5. Run with Docker Directly

```bash
docker run -d \
  --name coolify-mcp \
  --restart unless-stopped \
  -p 8000:8000 \
  -e COOLIFY_BASE_URL=https://coolify.yourdomain.com \
  -e COOLIFY_ACCESS_TOKEN=your-token \
  coolify-mcp:latest
```

## 6. Verify the Service

The SSE endpoint should be reachable at:

```bash
curl -N http://localhost:8000/sse
```

You should see an SSE connection open (event stream). Press Ctrl+C to close.

## Endpoints

| Path       | Description                                 |
| ---------- | ------------------------------------------- |
| `/sse`     | SSE event stream (MCP client connects here) |
| `/message` | Message handling endpoint                   |

## Troubleshooting

**Container exits immediately**: Check that `COOLIFY_ACCESS_TOKEN` is set. The server throws a fatal error without it.

**Connection refused on port 8000**: Verify the container is running with `docker ps`. Check logs with `docker logs coolify-mcp`.

**API errors**: Verify your `COOLIFY_BASE_URL` is correct and the token has sufficient permissions.
