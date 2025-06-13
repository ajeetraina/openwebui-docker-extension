#!/usr/bin/env python3
"""
Docker MCP Tools Server for OpenWebUI Integration
Provides Docker management capabilities via MCP protocol
"""

import asyncio
import json
import logging
from typing import Any, Dict, List, Optional
import docker
import subprocess
import os
from mcp.server.models import InitializationOptions
from mcp.server import NotificationOptions, Server
from mcp.types import (
    Resource,
    Tool,
    TextContent,
    ImageContent,
    EmbeddedResource,
)
import mcp.types as types

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("docker_mcp_server")

# Initialize Docker client
try:
    docker_client = docker.from_env()
    logger.info("✅ Docker client initialized successfully")
except Exception as e:
    logger.error(f"❌ Failed to initialize Docker client: {e}")
    docker_client = None

# Create MCP server instance
server = Server("docker-mcp-server")

@server.list_tools()
async def handle_list_tools() -> List[Tool]:
    """List all available Docker tools"""
    return [
        Tool(
            name="docker_list_containers",
            description="List Docker containers with optional filters",
            inputSchema={
                "type": "object",
                "properties": {
                    "all": {
                        "type": "boolean",
                        "description": "Show all containers (default: only running)",
                        "default": False
                    },
                    "filters": {
                        "type": "object",
                        "description": "Filter containers by status, name, etc.",
                        "properties": {
                            "status": {"type": "string"},
                            "name": {"type": "string"}
                        }
                    }
                }
            }
        ),
        Tool(
            name="docker_container_info",
            description="Get detailed information about a specific container",
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
        ),
        Tool(
            name="docker_container_logs",
            description="Get logs from a container",
            inputSchema={
                "type": "object",
                "properties": {
                    "container_id": {
                        "type": "string",
                        "description": "Container ID or name"
                    },
                    "lines": {
                        "type": "integer",
                        "description": "Number of lines to retrieve (default: 100)",
                        "default": 100
                    },
                    "follow": {
                        "type": "boolean",
                        "description": "Follow log output",
                        "default": False
                    }
                },
                "required": ["container_id"]
            }
        ),
        Tool(
            name="docker_container_stats",
            description="Get resource usage statistics for a container",
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
        ),
        Tool(
            name="docker_list_images",
            description="List Docker images",
            inputSchema={
                "type": "object",
                "properties": {
                    "all": {
                        "type": "boolean",
                        "description": "Show all images including intermediate layers",
                        "default": False
                    },
                    "filters": {
                        "type": "object",
                        "description": "Filter images by various criteria"
                    }
                }
            }
        ),
        Tool(
            name="docker_pull_image",
            description="Pull a Docker image from registry",
            inputSchema={
                "type": "object",
                "properties": {
                    "image": {
                        "type": "string",
                        "description": "Image name with optional tag (e.g., nginx:latest)"
                    },
                    "tag": {
                        "type": "string",
                        "description": "Specific tag to pull",
                        "default": "latest"
                    }
                },
                "required": ["image"]
            }
        ),
        Tool(
            name="docker_system_info",
            description="Get Docker system information and statistics",
            inputSchema={
                "type": "object",
                "properties": {}
            }
        ),
        Tool(
            name="docker_compose_services",
            description="List Docker Compose services in current directory",
            inputSchema={
                "type": "object",
                "properties": {
                    "project_path": {
                        "type": "string",
                        "description": "Path to docker-compose.yml directory",
                        "default": "."
                    }
                }
            }
        ),
        Tool(
            name="docker_compose_logs",
            description="Get logs from Docker Compose services",
            inputSchema={
                "type": "object",
                "properties": {
                    "service": {
                        "type": "string",
                        "description": "Service name (optional - all services if not specified)"
                    },
                    "lines": {
                        "type": "integer",
                        "description": "Number of lines to retrieve",
                        "default": 100
                    },
                    "project_path": {
                        "type": "string",
                        "description": "Path to docker-compose.yml directory",
                        "default": "."
                    }
                }
            }
        ),
        Tool(
            name="docker_network_list",
            description="List Docker networks",
            inputSchema={
                "type": "object",
                "properties": {
                    "filters": {
                        "type": "object",
                        "description": "Filter networks by various criteria"
                    }
                }
            }
        )
    ]

@server.call_tool()
async def handle_call_tool(name: str, arguments: Dict[str, Any]) -> List[types.TextContent]:
    """Handle tool calls"""
    
    if not docker_client:
        return [types.TextContent(
            type="text", 
            text="❌ Docker client not available. Please ensure Docker is running and accessible."
        )]
    
    try:
        if name == "docker_list_containers":
            return await _list_containers(arguments)
        elif name == "docker_container_info":
            return await _container_info(arguments)
        elif name == "docker_container_logs":
            return await _container_logs(arguments)
        elif name == "docker_container_stats":
            return await _container_stats(arguments)
        elif name == "docker_list_images":
            return await _list_images(arguments)
        elif name == "docker_pull_image":
            return await _pull_image(arguments)
        elif name == "docker_system_info":
            return await _system_info(arguments)
        elif name == "docker_compose_services":
            return await _compose_services(arguments)
        elif name == "docker_compose_logs":
            return await _compose_logs(arguments)
        elif name == "docker_network_list":
            return await _network_list(arguments)
        else:
            return [types.TextContent(
                type="text", 
                text=f"❌ Unknown tool: {name}"
            )]
    except Exception as e:
        logger.error(f"Error executing tool {name}: {e}")
        return [types.TextContent(
            type="text", 
            text=f"❌ Error executing {name}: {str(e)}"
        )]

async def _list_containers(args: Dict[str, Any]) -> List[types.TextContent]:
    """List Docker containers"""
    all_containers = args.get("all", False)
    filters = args.get("filters", {})
    
    containers = docker_client.containers.list(all=all_containers, filters=filters)
    
    if not containers:
        return [types.TextContent(
            type="text",
            text="📦 No containers found matching the criteria."
        )]
    
    result = "🐳 **Docker Containers**\n\n"
    for container in containers:
        status_emoji = "🟢" if container.status == "running" else "🔴"
        result += f"{status_emoji} **{container.name}**\n"
        result += f"   - ID: `{container.short_id}`\n"
        result += f"   - Image: `{container.image.tags[0] if container.image.tags else 'N/A'}`\n"
        result += f"   - Status: `{container.status}`\n"
        result += f"   - Ports: {container.ports}\n\n"
    
    return [types.TextContent(type="text", text=result)]

async def _container_info(args: Dict[str, Any]) -> List[types.TextContent]:
    """Get detailed container information"""
    container_id = args["container_id"]
    
    try:
        container = docker_client.containers.get(container_id)
        info = container.attrs
        
        result = f"🔍 **Container Details: {container.name}**\n\n"
        result += f"**Basic Info:**\n"
        result += f"- ID: `{container.id}`\n"
        result += f"- Image: `{info['Config']['Image']}`\n"
        result += f"- Status: `{container.status}`\n"
        result += f"- Created: `{info['Created']}`\n"
        result += f"- Started: `{info['State']['StartedAt']}`\n\n"
        
        result += f"**Network:**\n"
        for network_name, network_info in info['NetworkSettings']['Networks'].items():
            result += f"- {network_name}: `{network_info.get('IPAddress', 'N/A')}`\n"
        
        result += f"\n**Mounts:**\n"
        for mount in info.get('Mounts', []):
            result += f"- `{mount['Source']}` → `{mount['Destination']}`\n"
        
        return [types.TextContent(type="text", text=result)]
        
    except docker.errors.NotFound:
        return [types.TextContent(
            type="text",
            text=f"❌ Container '{container_id}' not found."
        )]

async def _container_logs(args: Dict[str, Any]) -> List[types.TextContent]:
    """Get container logs"""
    container_id = args["container_id"]
    lines = args.get("lines", 100)
    
    try:
        container = docker_client.containers.get(container_id)
        logs = container.logs(tail=lines, timestamps=True).decode('utf-8')
        
        result = f"📋 **Logs for {container.name}** (last {lines} lines)\n\n"
        result += f"```\n{logs}\n```"
        
        return [types.TextContent(type="text", text=result)]
        
    except docker.errors.NotFound:
        return [types.TextContent(
            type="text",
            text=f"❌ Container '{container_id}' not found."
        )]

async def _container_stats(args: Dict[str, Any]) -> List[types.TextContent]:
    """Get container resource usage statistics"""
    container_id = args["container_id"]
    
    try:
        container = docker_client.containers.get(container_id)
        stats = container.stats(stream=False)
        
        # Calculate CPU percentage
        cpu_delta = stats['cpu_stats']['cpu_usage']['total_usage'] - \
                   stats['precpu_stats']['cpu_usage']['total_usage']
        system_delta = stats['cpu_stats']['system_cpu_usage'] - \
                      stats['precpu_stats']['system_cpu_usage']
        cpu_percent = 0.0
        if system_delta > 0:
            cpu_percent = (cpu_delta / system_delta) * 100.0
        
        # Memory usage
        memory_usage = stats['memory_stats']['usage']
        memory_limit = stats['memory_stats']['limit']
        memory_percent = (memory_usage / memory_limit) * 100.0
        
        result = f"📊 **Resource Usage: {container.name}**\n\n"
        result += f"**CPU Usage:** {cpu_percent:.2f}%\n"
        result += f"**Memory Usage:** {memory_usage / (1024**2):.1f}MB / {memory_limit / (1024**2):.1f}MB ({memory_percent:.1f}%)\n"
        
        # Network I/O
        if 'networks' in stats:
            result += f"\n**Network I/O:**\n"
            for interface, net_stats in stats['networks'].items():
                rx_bytes = net_stats['rx_bytes'] / (1024**2)
                tx_bytes = net_stats['tx_bytes'] / (1024**2)
                result += f"- {interface}: RX {rx_bytes:.1f}MB, TX {tx_bytes:.1f}MB\n"
        
        return [types.TextContent(type="text", text=result)]
        
    except docker.errors.NotFound:
        return [types.TextContent(
            type="text",
            text=f"❌ Container '{container_id}' not found."
        )]

async def _list_images(args: Dict[str, Any]) -> List[types.TextContent]:
    """List Docker images"""
    all_images = args.get("all", False)
    filters = args.get("filters", {})
    
    images = docker_client.images.list(all=all_images, filters=filters)
    
    if not images:
        return [types.TextContent(
            type="text",
            text="📦 No images found matching the criteria."
        )]
    
    result = "🖼️ **Docker Images**\n\n"
    for image in images:
        tags = image.tags if image.tags else ["<none>"]
        size_mb = image.attrs['Size'] / (1024**2)
        result += f"**{tags[0]}**\n"
        result += f"   - ID: `{image.short_id}`\n"
        result += f"   - Size: `{size_mb:.1f}MB`\n"
        result += f"   - Created: `{image.attrs['Created']}`\n\n"
    
    return [types.TextContent(type="text", text=result)]

async def _pull_image(args: Dict[str, Any]) -> List[types.TextContent]:
    """Pull a Docker image"""
    image_name = args["image"]
    tag = args.get("tag", "latest")
    
    full_image = f"{image_name}:{tag}" if ":" not in image_name else image_name
    
    try:
        result = f"⬇️ **Pulling image: {full_image}**\n\n"
        image = docker_client.images.pull(full_image)
        result += f"✅ Successfully pulled `{full_image}`\n"
        result += f"Image ID: `{image.short_id}`\n"
        
        return [types.TextContent(type="text", text=result)]
        
    except Exception as e:
        return [types.TextContent(
            type="text",
            text=f"❌ Failed to pull image '{full_image}': {str(e)}"
        )]

async def _system_info(args: Dict[str, Any]) -> List[types.TextContent]:
    """Get Docker system information"""
    try:
        info = docker_client.info()
        version = docker_client.version()
        
        result = "🐳 **Docker System Information**\n\n"
        result += f"**Version:** {version['Version']}\n"
        result += f"**API Version:** {version['ApiVersion']}\n"
        result += f"**OS/Arch:** {info['OperatingSystem']} / {info['Architecture']}\n"
        result += f"**Total Memory:** {info['MemTotal'] / (1024**3):.1f}GB\n"
        result += f"**CPUs:** {info['NCPU']}\n\n"
        
        result += f"**Containers:**\n"
        result += f"- Running: {info['ContainersRunning']}\n"
        result += f"- Stopped: {info['ContainersStopped']}\n"
        result += f"- Paused: {info['ContainersPaused']}\n\n"
        
        result += f"**Images:** {info['Images']}\n"
        result += f"**Server Version:** {info['ServerVersion']}\n"
        
        return [types.TextContent(type="text", text=result)]
        
    except Exception as e:
        return [types.TextContent(
            type="text",
            text=f"❌ Failed to get system info: {str(e)}"
        )]

async def _compose_services(args: Dict[str, Any]) -> List[types.TextContent]:
    """List Docker Compose services"""
    project_path = args.get("project_path", ".")
    
    try:
        cmd = ["docker-compose", "-f", f"{project_path}/docker-compose.yaml", "ps"]
        result_cmd = subprocess.run(cmd, capture_output=True, text=True, cwd=project_path)
        
        if result_cmd.returncode != 0:
            return [types.TextContent(
                type="text",
                text=f"❌ Failed to list compose services: {result_cmd.stderr}"
            )]
        
        result = f"🐙 **Docker Compose Services**\n\n"
        result += f"```\n{result_cmd.stdout}\n```"
        
        return [types.TextContent(type="text", text=result)]
        
    except Exception as e:
        return [types.TextContent(
            type="text",
            text=f"❌ Error running docker-compose: {str(e)}"
        )]

async def _compose_logs(args: Dict[str, Any]) -> List[types.TextContent]:
    """Get Docker Compose service logs"""
    service = args.get("service", "")
    lines = args.get("lines", 100)
    project_path = args.get("project_path", ".")
    
    try:
        cmd = ["docker-compose", "-f", f"{project_path}/docker-compose.yaml", "logs", "--tail", str(lines)]
        if service:
            cmd.append(service)
        
        result_cmd = subprocess.run(cmd, capture_output=True, text=True, cwd=project_path)
        
        if result_cmd.returncode != 0:
            return [types.TextContent(
                type="text",
                text=f"❌ Failed to get compose logs: {result_cmd.stderr}"
            )]
        
        service_text = f" for {service}" if service else ""
        result = f"📋 **Docker Compose Logs{service_text}**\n\n"
        result += f"```\n{result_cmd.stdout}\n```"
        
        return [types.TextContent(type="text", text=result)]
        
    except Exception as e:
        return [types.TextContent(
            type="text",
            text=f"❌ Error getting compose logs: {str(e)}"
        )]

async def _network_list(args: Dict[str, Any]) -> List[types.TextContent]:
    """List Docker networks"""
    filters = args.get("filters", {})
    
    try:
        networks = docker_client.networks.list(filters=filters)
        
        if not networks:
            return [types.TextContent(
                type="text",
                text="🌐 No networks found matching the criteria."
            )]
        
        result = "🌐 **Docker Networks**\n\n"
        for network in networks:
            result += f"**{network.name}**\n"
            result += f"   - ID: `{network.short_id}`\n"
            result += f"   - Driver: `{network.attrs['Driver']}`\n"
            result += f"   - Scope: `{network.attrs['Scope']}`\n"
            
            # List connected containers
            containers = network.attrs.get('Containers', {})
            if containers:
                result += f"   - Containers: {len(containers)} connected\n"
            result += "\n"
        
        return [types.TextContent(type="text", text=result)]
        
    except Exception as e:
        return [types.TextContent(
            type="text",
            text=f"❌ Error listing networks: {str(e)}"
        )]

async def main():
    """Main server entry point"""
    # Transport setup will be handled by mcpo
    async with server as ctx:
        await ctx.request_context.session.send_log_message(
            level="info",
            data="🐳 Docker MCP Server started successfully"
        )
        
        # Keep server running
        await asyncio.Event().wait()

if __name__ == "__main__":
    asyncio.run(main())
