#!/bin/bash

# MCP Server Entrypoint Script
# Starts the MCP-to-OpenAPI proxy (mcpo) with Docker MCP tools

set -e

echo "🐳 Starting Docker MCP Server with OpenAPI proxy..."

# Set default port
MCP_PORT=${MCP_PORT:-8001}

echo "📡 Starting mcpo proxy on port $MCP_PORT"
echo "🔧 MCP Tools: Docker management and monitoring"

# Check if Docker socket is accessible
if [ ! -S /var/run/docker.sock ]; then
    echo "⚠️  Warning: Docker socket not found at /var/run/docker.sock"
    echo "   Make sure to mount the Docker socket as a volume:"
    echo "   -v /var/run/docker.sock:/var/run/docker.sock"
fi

# Start mcpo with our Docker MCP tools server
exec mcpo \
    --host 0.0.0.0 \
    --port $MCP_PORT \
    --cors \
    --verbose \
    -- python3 docker_mcp_tools.py
