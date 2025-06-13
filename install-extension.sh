#!/bin/bash

# OpenWebUI Docker Extension - Build and Install Script
# This script validates the build and installs the extension

set -e

echo "🔧 OpenWebUI Docker Extension with MCP Integration"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker Desktop and try again."
    exit 1
fi

print_status "Docker is running"

# Check if required files exist
echo "🔍 Validating required files..."

required_files=(
    "docker-compose.yaml"
    "metadata.json"
    "mcp/Dockerfile"
    "mcp/docker_mcp_tools.py"
    "mcp/requirements.txt"
    "mcp/entrypoint.sh"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        print_status "Found: $file"
    else
        print_error "Missing required file: $file"
        exit 1
    fi
done

# Validate docker-compose.yaml syntax
echo "🔍 Validating docker-compose.yaml..."
if docker compose -f docker-compose.yaml config >/dev/null 2>&1; then
    print_status "docker-compose.yaml syntax is valid"
else
    print_error "docker-compose.yaml has syntax errors"
    docker compose -f docker-compose.yaml config
    exit 1
fi

# Test MCP Dockerfile build context
echo "🔍 Testing MCP build context..."
if docker build -f mcp/Dockerfile -t test-mcp-build . >/dev/null 2>&1; then
    print_status "MCP Dockerfile build context is valid"
    docker rmi test-mcp-build >/dev/null 2>&1
else
    print_error "MCP Dockerfile build failed"
    print_warning "This might be due to missing dependencies. Check the build output above."
fi

# Remove existing extension if it exists
echo "🧹 Cleaning up existing extension..."
if docker extension ls | grep -q "openwebui-model-runner"; then
    print_warning "Removing existing OpenWebUI extension..."
    docker extension rm openwebui-model-runner --force >/dev/null 2>&1 || true
fi

# Build the extension
echo "🔨 Building OpenWebUI Docker Extension..."
if docker buildx build -t openwebui-model-runner:latest . --load; then
    print_status "Extension built successfully"
else
    print_error "Extension build failed"
    exit 1
fi

# Install the extension
echo "📦 Installing OpenWebUI Docker Extension..."
if docker extension install openwebui-model-runner:latest --force; then
    print_status "Extension installed successfully"
else
    print_error "Extension installation failed"
    exit 1
fi

# Wait a moment for services to start
echo "⏳ Waiting for services to start..."
sleep 10

# Check if services are running
echo "🔍 Checking service health..."

# Check OpenWebUI
if curl -s http://localhost:8090 >/dev/null 2>&1; then
    print_status "OpenWebUI is accessible at http://localhost:8090"
else
    print_warning "OpenWebUI might still be starting up. Check http://localhost:8090 in a few moments."
fi

# Check MCP Proxy
if curl -s http://localhost:8001/docs >/dev/null 2>&1; then
    print_status "MCP Proxy is accessible at http://localhost:8001/docs"
else
    print_warning "MCP Proxy might still be starting up. Check http://localhost:8001/docs in a few moments."
fi

# Show service status
echo "📊 Service Status:"
docker ps --filter "label=com.docker.desktop.extension=true" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "🎉 Installation Complete!"
echo ""
echo "📍 Access Points:"
echo "   • OpenWebUI: http://localhost:8090"
echo "   • MCP API Docs: http://localhost:8001/docs"
echo ""
echo "🧪 Test MCP Integration:"
echo "   1. Open OpenWebUI at http://localhost:8090"
echo "   2. Ask: 'Show me all running containers'"
echo "   3. Ask: 'What's the Docker system status?'"
echo ""
echo "🐛 Troubleshooting:"
echo "   • Check logs: docker logs openwebui-mcp-proxy"
echo "   • Test MCP API: curl http://localhost:8001/docs"
echo "   • View containers: docker ps"
echo ""
echo "Happy Docker management with AI! 🚀"
