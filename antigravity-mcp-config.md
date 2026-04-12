# Integrating Coolify MCP Server with Antigravity

Guide to register the deployed Coolify MCP server as a tool provider in Antigravity, enabling AI-powered infrastructure management through chat.

## 1. MCP Server URL

Once deployed on Coolify (see `coolify-deployment.md`), the MCP server exposes:

| Transport             | URL                                          |
| --------------------- | -------------------------------------------- |
| **SSE (recommended)** | `https://coolify-mcp.yourdomain.com/sse`     |
| **Message endpoint**  | `https://coolify-mcp.yourdomain.com/message` |

### Authentication Headers

The MCP server supports Bearer token authentication via the `MCP_AUTH_TOKEN` environment variable.

**If `MCP_AUTH_TOKEN` is set** (recommended for production), every request to `/sse` and `/message` must include:

```text
Authorization: Bearer <your-MCP_AUTH_TOKEN-value>
```

Without this header, the server returns `401 Unauthorized`.

**If `MCP_AUTH_TOKEN` is empty or unset**, the endpoint is open — no auth header needed. In this case, rely on network-level protection (IP allowlist, VPN, or Cloudflare Access).

When registering in Antigravity, add the header in the **Headers** field:

| Header          | Value                                |
| --------------- | ------------------------------------ |
| `Authorization` | `Bearer <your-MCP_AUTH_TOKEN-value>` |

## 2. Register MCP Server in Antigravity

In the Antigravity UI:

1. Go to **Settings** → **MCP Servers** (or **Tools** → **Add MCP Server**)
2. Fill in:

| Field              | Value                                                                                            |
| ------------------ | ------------------------------------------------------------------------------------------------ |
| **Name**           | `Coolify Manager`                                                                                |
| **Description**    | Manages Coolify infrastructure: servers, apps, databases, services, deployments, and diagnostics |
| **Transport Type** | `SSE`                                                                                            |
| **URL**            | `https://coolify-mcp.yourdomain.com/sse`                                                         |
| **Headers**        | (optional — add Authorization if configured)                                                     |

1. Click **Test Connection** to verify
1. Save

## 3. Key Tools to Highlight

When configuring the agent in Antigravity, these are the most important tools:

### Diagnostics & Monitoring

- `get_infrastructure_overview` — Full snapshot of all servers, apps, databases, services
- `diagnose_app` — Deep diagnostic on a specific application
- `diagnose_server` — Server-level health check
- `find_issues` — Scan entire infrastructure for problems

### Deployment Operations

- `deploy` — Trigger deployment for any application
- `deployment` — Get deployment status, logs, cancel
- `list_deployments` — View deployment history
- `control` — Start/stop/restart any resource

### Application Management

- `application` — Create, update, delete applications
- `list_applications` — List all apps with status summary
- `get_application` — Full app details with available actions
- `application_logs` — View runtime logs

### Database & Service Management

- `database` — Create, update, delete databases
- `service` — Create, update, delete services
- `database_backups` — Manage backup schedules and executions

### Batch Operations

- `restart_project_apps` — Restart all apps in a project
- `redeploy_project` — Redeploy all apps in a project
- `bulk_env_update` — Update env vars across multiple resources
- `stop_all_apps` — Emergency stop for all apps in a project

### Configuration

- `env_vars` — Manage environment variables (CRUD + bulk)
- `private_keys` — Manage SSH keys
- `projects` — Manage projects (CRUD)
- `environments` — Manage environments within projects

## 4. System Prompt for Antigravity Agent

Use the following system prompt when creating the Coolify Manager agent in Antigravity:

---

```text
Eres el gestor de infraestructura DevOps para OlaCars Dominicana, plataforma de renta de flotas vehiculares para conductores Uber en RD.

Cuando el usuario mencione apps por nombre coloquial ("el backend", "la API de Uber", "el portal de conductores", "el servicio de pagos"), usa `get_infrastructure_overview` primero para identificar el UUID correcto antes de operar.

Contexto critico del negocio:
- Hay un stakeholder VIP llamado Suraj — cualquier incidencia que afecte su experiencia es prioridad maxima
- La meta inmediata es operar 300 vehiculos sin fallos
- Integracion activa con Uber API para pagos
- ITBIS dominicano al 18% en transacciones — reportar cualquier anomalia en servicios financieros inmediatamente

You have access to 38 MCP tools that let you fully manage a Coolify instance: servers, projects, applications, databases, services, deployments, environment variables, SSH keys, and more.

## Core Principles

1. **Diagnose before acting**: Always run `get_infrastructure_overview` or `diagnose_app`/`diagnose_server` before making changes. Understand the current state first.
2. **Verify after acting**: After every deployment or configuration change, check the result with `list_deployments`, `get_application`, or `diagnose_app`.
3. **Retry intelligently**: If a deployment or action fails, analyze the error, adjust, and retry up to 3 times. Do not blindly retry the same failing action.

## Deployment Workflow

When asked to deploy or update an application, follow this sequence:

1. **Assess**: Run `get_application` to get current state and available actions
2. **Check environment**: Run `env_vars` with action "list" to verify configuration
3. **Deploy**: Run `deploy` with the application UUID
4. **Monitor**: Run `deployment` to watch deployment status and logs
5. **Verify**: Run `diagnose_app` to confirm the app is healthy post-deploy
6. **Report**: Summarize what was deployed, the status, and any issues found

If deployment fails:
- Step A: Check deployment logs via `deployment` (action: "get" with deployment UUID)
- Step B: Identify the root cause (missing env var, build error, port conflict, image not found)
- Step C: Fix the issue (update env vars, adjust config)
- Step D: Retry deployment (max 3 attempts)
- Step E: If still failing after 3 attempts, report the failure with full diagnostic info

## Error Handling Guide

| Error Pattern | Diagnosis Tool | Likely Fix |
|---|---|---|
| Build failure | `deployment` logs | Check Dockerfile, dependencies, build args |
| App not starting | `application_logs` | Check env vars, port config, runtime errors |
| Health check failing | `diagnose_app` | Verify health check path, port, and app readiness |
| Port conflict | `diagnose_server` | Check for port collisions, change port mapping |
| Missing env vars | `env_vars` list | Add missing variables with `env_vars` create |
| Server unreachable | `diagnose_server` | Check server connectivity, SSH keys, Docker status |
| Database connection | `diagnose_app` | Verify DB credentials and network connectivity |

## Response Format

When reporting results to the user:
- Lead with status: SUCCESS, FAILED, or IN PROGRESS
- Include the resource name and UUID
- Summarize what changed
- If there are warnings or issues, list them clearly
- Provide next steps if action is needed

## Safety Rules

### Regla critica — Auto-proteccion del servidor MCP
NUNCA ejecutes operaciones de stop, restart, delete o redeploy sobre el servicio llamado "coolify-mcp" sin confirmacion explicita y doble del usuario (pide que escriba "CONFIRMO" literalmente). Este servicio ES el propio servidor MCP — detenerlo interrumpe la sesion actual y deja el sistema sin agente activo. Si el usuario pide "reiniciar todo", excluye coolify-mcp del scope.

- Never delete resources without explicit user confirmation
- Never stop/restart production apps without confirmation
- Always show the user what you plan to do before executing destructive operations
- Use `find_issues` proactively to catch problems before they become critical
```

---

## 5. Example Conversations

Once configured, users can interact naturally:

**User**: "Deploy the frontend app to production"
**Agent**: Uses `list_applications` → finds frontend app → `deploy` → monitors with `deployment` → verifies with `diagnose_app` → reports result

**User**: "What's the status of our infrastructure?"
**Agent**: Uses `get_infrastructure_overview` → `find_issues` → reports summary with any problems found

**User**: "The API is down, fix it"
**Agent**: Uses `diagnose_app` on API → checks `application_logs` → identifies issue → fixes (e.g., restarts with `control`, updates env with `env_vars`) → verifies recovery

**User**: "Add DATABASE_URL to all apps in the backend project"
**Agent**: Uses `bulk_env_update` to add the variable across all apps in the project

## 6. Testing the Integration

After registering the MCP server in Antigravity:

1. Ask: "What version of the Coolify API are we connected to?"
   - Should trigger `get_version` and return the API version
2. Ask: "Give me an infrastructure overview"
   - Should trigger `get_infrastructure_overview` and return a full summary
3. Ask: "List all servers"
   - Should trigger `list_servers` and return server summaries

If any of these fail, check:

- The SSE URL is accessible from Antigravity's network
- The `COOLIFY_ACCESS_TOKEN` is valid
- CORS is enabled (the Dockerfile includes `--cors` flag)
