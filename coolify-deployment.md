# Deploying Coolify MCP Server on Coolify

Step-by-step guide to deploy this MCP server as a containerized service on your Coolify instance.

## Prerequisites

- Coolify instance running and accessible
- Admin access to create services and API tokens
- This repository accessible from Coolify (public GitHub or configured deploy key)

## Step 1: Generate a Coolify API Token

1. Go to your Coolify dashboard
2. Navigate to **Settings** (gear icon) → **API**
3. Click **Generate New Token**
4. Give it a descriptive name: `mcp-server-token`
5. Copy the token and save it securely

## Step 2: Create the Service in Coolify

### Option A: From GitHub Repository (Recommended)

1. In Coolify UI, click **+ New** → **Service** → **From a Git Repository**
2. Select your GitHub source or add the repository URL:
   `https://github.com/StuMason/coolify-mcp.git`
   (or your fork)
3. Select the branch: `main`

### Option B: From Docker Image

If you pre-build and push to a registry:

1. Click **+ New** → **Service** → **From a Docker Image**
2. Image: `your-registry/coolify-mcp:latest`

## Step 3: Configure Build Settings

| Setting             | Value          |
| ------------------- | -------------- |
| **Build Pack**      | Dockerfile     |
| **Dockerfile Path** | `./Dockerfile` |
| **Build Context**   | `.` (root)     |
| **Port**            | `8000`         |

## Step 4: Set Environment Variables

In the service's **Environment Variables** section, add:

| Variable               | Value                             | Secret? |
| ---------------------- | --------------------------------- | ------- |
| `COOLIFY_BASE_URL`     | `https://your-coolify.domain.com` | No      |
| `COOLIFY_ACCESS_TOKEN` | `<token-from-step-1>`             | **Yes** |
| `MCP_PORT`             | `8000`                            | No      |
| `NODE_ENV`             | `production`                      | No      |

**Important**: The `COOLIFY_BASE_URL` should be the URL of the Coolify instance this server will manage. This creates a self-managing loop — the MCP server deployed ON Coolify manages THAT SAME Coolify instance.

## Step 5: Configure Domain

1. In the service settings, go to **Domains**
2. Add your domain: `coolify-mcp.yourdomain.com`
3. Enable **HTTPS** (Let's Encrypt auto-configured by Coolify)
4. The final endpoint will be: `https://coolify-mcp.yourdomain.com/sse`

## Step 6: Configure Health Check

In the service's **Health Check** section:

| Setting                   | Value  |
| ------------------------- | ------ |
| **Health Check Path**     | `/sse` |
| **Health Check Port**     | `8000` |
| **Health Check Interval** | `30s`  |
| **Health Check Timeout**  | `5s`   |
| **Health Check Retries**  | `3`    |
| **Start Period**          | `10s`  |

## Step 7: Configure Restart Policy

| Setting            | Value            |
| ------------------ | ---------------- |
| **Restart Policy** | `unless-stopped` |

## Step 8: Deploy

1. Click **Deploy** in the Coolify UI
2. Watch the build logs — it should:
   - Pull node:20-alpine
   - Install dependencies
   - Compile TypeScript
   - Install supergateway
   - Start the SSE server on port 8000
3. Wait for the health check to pass (green status)

## Step 9: Verify

Test the SSE endpoint:

```bash
curl -N https://coolify-mcp.yourdomain.com/sse
```

You should see an SSE event stream open. This confirms the MCP server is accessible over HTTP.

## Troubleshooting

### Build Fails

- Check that the Dockerfile is found at the root of the repository
- Verify `node:20-alpine` is accessible from your Coolify server

### Container Starts but Health Check Fails

- Check logs in Coolify UI → Service → Logs
- Verify `COOLIFY_ACCESS_TOKEN` is set (the server crashes without it)
- Ensure port 8000 is correctly mapped

### SSE Connection Drops

- Check if Coolify's reverse proxy (Traefik/Caddy) has SSE-compatible timeouts
- You may need to increase proxy read timeout for long-lived SSE connections
- In Coolify's Traefik config, ensure `respondingTimeouts.readTimeout` is set high (e.g., `600s`)

### Self-Management Circular Dependency

The MCP server manages the same Coolify instance it runs on. If the MCP server is used to modify its own service, it could cause a restart loop. To mitigate:

- Use the MCP server to manage OTHER services, not itself
- If you must manage it, use the Coolify UI directly for the MCP service
