## OpenWebUI Docker Extension for Docker Model Runner


Open WebUI Extension is a single-click installer of Docker Model Runner and Open WebUI for your Docker Desktop.



## Try it now

```
$ docker extension install ajeetraina777/openwebui-model-runner:3.0
```

This repository defines an example of a Docker extension. The files in this repository have been automatically generated as a result of running `docker extension init`.

This extension is composed of:

- A [frontend](./ui) app in React that makes a request to the `/hello` endpoint and displays the payload in Docker Desktop.
- A [backend](./backend) container that runs an API in Go. It exposes the `/hello` endpoint which returns a JSON payload.
- A [MCP proxy](./mcp) service that provides AI-powered Docker management through natural language.

> You can build your Docker Extension using your fav tech stack:
>
> - Frontend: React, Angular, Vue, Svelte, etc.
>   Basically, any frontend framework you can bundle in an `index.html` file with CSS, and JS assets.
> - Backend (optional): anything that can run in a container.

<details>
  <summary>Looking for more templates?</summary>

1. [React + NodeJS](https://github.com/benja-M-1/node-backend-extension).
2. [React + .NET 6 WebAPI](https://github.com/felipecruz91/dotnet-api-docker-extension).

Request one or submit yours [here](https://github.com/docker/extensions-sdk/issues).

</details>

# 🛰️ MCP (Model Context Protocol) Integration

This OpenWebUI Docker Extension now includes full **Model Context Protocol (MCP)** support, providing powerful Docker management capabilities directly through AI chat interfaces.

## 🌟 What is MCP Integration?

The MCP integration adds intelligent Docker management tools that allow you to:

- **Manage Containers**: List, inspect, start/stop containers via chat
- **Monitor Resources**: Get real-time stats and logs for any container
- **Handle Images**: Pull images, list available images with details
- **Network Operations**: View and manage Docker networks
- **Compose Management**: Work with Docker Compose services
- **System Monitoring**: Get Docker system information and health status

## 🚀 Quick Start

1. **Install the Extension**:
   ```bash
   docker extension install ajeetraina777/openwebui-model-runner:3.0
   ```

2. **Access OpenWebUI**: Navigate to `http://localhost:8090`

3. **Start Using MCP Tools**: Ask the AI assistant things like:
   - "Show me all running containers"
   - "Get logs for the web container"
   - "What's the resource usage of my app?"
   - "List all Docker images on this system"
   - "Pull the latest nginx image"

## 🔧 Architecture

```
┌─────────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   OpenWebUI        │    │   MCP Proxy      │    │  Docker MCP     │
│   (Port 8090)      │◄──►│   (Port 8001)    │◄──►│  Tools Server   │
│                    │    │   (mcpo)         │    │                 │
└─────────────────────┘    └──────────────────┘    └─────────────────┘
                                     │
                                     ▼
                           ┌─────────────────┐
                           │  Docker Engine  │
                           │  /var/run/      │
                           │  docker.sock    │
                           └─────────────────┘
```

## 📋 Available MCP Tools

### Container Management
- **`docker_list_containers`**: List all containers with status and details
- **`docker_container_info`**: Get detailed information about a specific container
- **`docker_container_logs`**: Retrieve container logs with customizable line count
- **`docker_container_stats`**: Get real-time resource usage statistics

### Image Management
- **`docker_list_images`**: List all Docker images with size and metadata
- **`docker_pull_image`**: Pull images from registries

### System Information
- **`docker_system_info`**: Get Docker system information, version, and resource usage

### Docker Compose
- **`docker_compose_services`**: List services in Docker Compose projects
- **`docker_compose_logs`**: Get logs from Compose services

### Network Management
- **`docker_network_list`**: List Docker networks and their configurations

## 🛠️ Configuration

### Environment Variables

The MCP proxy service supports several configuration options:

```yaml
environment:
  - MCP_PORT=8001                    # Port for MCP proxy server
  - DOCKER_HOST=unix:///var/run/docker.sock  # Docker socket path
```

### OpenWebUI MCP Settings

The OpenWebUI service is automatically configured to use MCP tools:

```yaml
environment:
  - ENABLE_OPENAPI_FUNCTIONS=true    # Enable OpenAPI function calling
  - OPENAPI_FUNCTIONS_URL=http://mcp-proxy:8001  # MCP proxy endpoint
```

## 📖 Usage Examples

### Basic Container Operations

**List Running Containers:**
```
User: "What containers are currently running?"
AI: [Uses docker_list_containers] 
    🐳 Docker Containers
    🟢 openwebui-model-runner
       - ID: abc123def
       - Image: ajeetraina777/openwebui-docker-extension:2.0
       - Status: running
       - Ports: {'8080/tcp': [{'HostIp': '0.0.0.0', 'HostPort': '8090'}]}
```

**Get Container Logs:**
```
User: "Show me the recent logs for the openwebui container"
AI: [Uses docker_container_logs]
    📋 Logs for openwebui-model-runner (last 100 lines)
    [timestamp] INFO: Starting OpenWebUI server...
    [timestamp] INFO: Model runner connection established...
```

### Resource Monitoring

**Check Resource Usage:**
```
User: "How much CPU and memory is the web container using?"
AI: [Uses docker_container_stats]
    📊 Resource Usage: openwebui-model-runner
    CPU Usage: 2.34%
    Memory Usage: 245.3MB / 2048.0MB (12.0%)
    Network I/O:
    - eth0: RX 15.2MB, TX 8.7MB
```

### Image Management

**Pull New Images:**
```
User: "Pull the latest redis image"
AI: [Uses docker_pull_image]
    ⬇️ Pulling image: redis:latest
    ✅ Successfully pulled redis:latest
    Image ID: 4c8
```

### System Information

**Get Docker System Status:**
```
User: "What's the status of the Docker system?"
AI: [Uses docker_system_info]
    🐳 Docker System Information
    Version: 24.0.7
    OS/Arch: Linux / x86_64
    Total Memory: 16.0GB
    CPUs: 8
    Containers:
    - Running: 3
    - Stopped: 1
    - Paused: 0
    Images: 15
```

## 🔍 API Documentation

The MCP proxy automatically generates interactive API documentation available at:
**http://localhost:8001/docs**

This Swagger UI interface shows:
- All available MCP tools
- Input/output schemas
- Interactive testing interface
- Authentication requirements

## 🛡️ Security Considerations

### Docker Socket Access
- The MCP proxy has **read-only** access to the Docker socket by default
- Container operations are limited to inspection and monitoring
- No destructive operations (delete, stop, restart) are exposed

### Network Isolation
- MCP proxy runs in the same Docker network as OpenWebUI
- Not directly accessible from outside the Docker extension

### User Permissions
- MCP tools respect Docker daemon permissions
- Operations are limited to what the Docker socket allows

## 🔧 Development & Customization

### Adding New MCP Tools

To add custom Docker tools:

1. **Edit `mcp/docker_mcp_tools.py`**
2. **Add tool definition** in `handle_list_tools()`
3. **Implement tool logic** in `handle_call_tool()`
4. **Rebuild the extension**

Example tool addition:
```python
Tool(
    name="docker_container_restart",
    description="Restart a container",
    inputSchema={
        "type": "object",
        "properties": {
            "container_id": {
                "type": "string",
                "description": "Container ID or name"
            }
        },
        "required": ["container_id"]
    }
)
```

### Local Development

For development with hot reloading:

```bash
# Start MCP proxy in development mode
cd mcp
python docker_mcp_tools.py

# In another terminal, start mcpo proxy
mcpo --port 8001 --cors -- python docker_mcp_tools.py
```

## 🐛 Troubleshooting

### Common Issues

**MCP Proxy Not Starting:**
- Check Docker socket is mounted: `-v /var/run/docker.sock:/var/run/docker.sock`
- Verify port 8001 is not in use
- Check container logs: `docker logs openwebui-mcp-proxy`

**Tools Not Available in OpenWebUI:**
- Ensure `ENABLE_OPENAPI_FUNCTIONS=true` in OpenWebUI environment
- Verify `OPENAPI_FUNCTIONS_URL=http://mcp-proxy:8001` is correct
- Check MCP proxy health: `curl http://localhost:8001/docs`

**Permission Errors:**
- Verify Docker socket permissions
- Check if user is in docker group (for development)

### Debug Commands

```bash
# Check MCP proxy status
curl http://localhost:8001/docs

# View MCP proxy logs
docker logs openwebui-mcp-proxy

# Test Docker socket access
docker exec openwebui-mcp-proxy docker ps

# List available tools
curl http://localhost:8001/tools
```

## Local development

You can use `docker` to build, install and push your extension. Also, we provide an opinionated [Makefile](Makefile) that could be convenient for you. There isn't a strong preference of using one over the other, so just use the one you're most comfortable with.

To build the extension, use `make build-extension` **or**:

```shell
  docker buildx build -t openwebui-model-runner:latest . --load
```

To install the extension, use `make install-extension` **or**:

```shell
  docker extension install openwebui-model-runner:3.0
```

> If you want to automate this command, use the `-f` or `--force` flag to accept the warning message.

To preview the extension in Docker Desktop, open Docker Dashboard once the installation is complete. The left-hand menu displays a new tab with the name of your extension. You can also use `docker extension ls` to see that the extension has been installed successfully.

### Frontend development

During the development of the frontend part, it's helpful to use hot reloading to test your changes without rebuilding your entire extension. To do this, you can configure Docker Desktop to load your UI from a development server.
Assuming your app runs on the default port, start your UI app and then run:

```shell
  cd ui
  npm install
  npm run dev
```

This starts a development server that listens on port `3000`.

You can now tell Docker Desktop to use this as the frontend source. In another terminal run:

```shell
  docker extension dev ui-source openwebui-model-runner:3.0 http://localhost:3000
```

In order to open the Chrome Dev Tools for your extension when you click on the extension tab, run:

```shell
  docker extension dev debug openwebui-model-runner:3.0
```

Each subsequent click on the extension tab will also open Chrome Dev Tools. To stop this behaviour, run:

```shell
  docker extension dev reset openwebui-model-runner:3.0
```

### Backend development (optional)

This example defines an API in Go that is deployed as a backend container when the extension is installed. This backend could be implemented in any language, as it runs inside a container. The extension frameworks provides connectivity from the extension UI to a socket that the backend has to connect to on the server side.

Note that an extension doesn't necessarily need a backend container, but in this example we include one for teaching purposes.

Whenever you make changes in the [backend](./backend) source code, you will need to compile them and re-deploy a new version of your backend container.
Use the `docker extension update` command to remove and re-install the extension automatically:

```shell
docker extension update openwebui-model-runner:3.0
```

> If you want to automate this command, use the `-f` or `--force` flag to accept the warning message.

> Extension containers are hidden from the Docker Dashboard by default. You can change this in Settings > Extensions > Show Docker Extensions system containers.

### Clean up

To remove the extension:

```shell
docker extension rm openwebui-model-runner:3.0
```

## 🤝 Contributing

To contribute to MCP integration:

1. Fork the repository
2. Create feature branch for MCP improvements
3. Add tests for new tools
4. Update documentation
5. Submit pull request

## 📚 Resources

- [OpenWebUI MCP Documentation](https://docs.openwebui.com/openapi-servers/mcp/)
- [Model Context Protocol Specification](https://github.com/modelcontextprotocol/specification)
- [MCP-to-OpenAPI Proxy (mcpo)](https://github.com/open-webui/mcpo)
- [Docker SDK for Python](https://docker-py.readthedocs.io/)

## What's next?

- To learn more about how to build your extension refer to the Extension SDK docs at https://docs.docker.com/desktop/extensions-sdk/.
- To publish your extension in the Marketplace visit https://www.docker.com/products/extensions/submissions/.
- To report issues and feedback visit https://github.com/docker/extensions-sdk/issues.
- To look for other ideas of new extensions, or propose new ideas of extensions you would like to see, visit https://github.com/docker/extension-ideas/discussions.

---

*The MCP integration makes this Docker extension incredibly powerful, allowing natural language control of your entire Docker environment!* 🚀
