#!/bin/bash

# OpenWebUI + Docker Model Runner Extension Installation Script
# This script simplifies docker-compose.yaml and installs the extension

set -e  # Exit on any error

echo "🚀 Installing OpenWebUI + Docker Model Runner Extension"
echo "=================================================="

# Backup current docker-compose.yaml
echo "📦 Backing up current docker-compose.yaml..."
cp docker-compose.yaml "docker-compose.backup-$(date +%Y%m%d-%H%M%S).yaml"
echo "✅ Backup created"

# Create simplified docker-compose.yaml for extension
echo "📝 Creating simplified docker-compose.yaml..."
cat > docker-compose.yaml << 'EOF'
services:
  openwebui:
    build:
      context: .
      dockerfile: Dockerfile
    image: openwebui-model-runner:latest
    container_name: openwebui-model-runner
    volumes:
      - openwebui-data:/app/backend/data
    ports:
      - "3001:8080"
    environment:
      - OPENAI_API_BASE_URL=http://model-runner.docker.internal/engines/llama.cpp/v1
      - OPENAI_API_KEY=dockermodelrunner
      - ENABLE_OLLAMA_API=false
      - ENABLE_OPENAI_API=true
      - WEBUI_NAME=OpenWebUI + Docker Model Runner
      - WEBUI_AUTH=false
      - ENABLE_SIGNUP=true
      - DEFAULT_USER_ROLE=user
      - ENABLE_MODEL_FILTER=true
      - ENABLE_COMMUNITY_SHARING=false
      - CORS_ALLOW_ORIGIN=*
    extra_hosts:
      - "host.docker.internal:host-gateway"
      - "model-runner.docker.internal:host-gateway"
    networks:
      - openwebui-network
    restart: unless-stopped
    labels:
      - "com.docker.desktop.extension=true"
      - "com.docker.desktop.extension.api.version=>=0.3.4"

volumes:
  openwebui-data:
    driver: local

networks:
  openwebui-network:
    driver: bridge
EOF

echo "✅ Simplified docker-compose.yaml created"

# Install the extension
echo "🔧 Installing Docker Desktop Extension..."
echo "Running: make install-extension"

if make install-extension; then
    echo ""
    echo "🎉 SUCCESS! Extension installed successfully!"
    echo "=================================================="
    echo "✅ OpenWebUI + Docker Model Runner extension is now available in Docker Desktop"
    echo "🌐 Access OpenWebUI at: http://localhost:3001"
    echo "🔧 Make sure Docker Model Runner is enabled in Docker Desktop"
    echo ""
    echo "Next steps:"
    echo "1. Open Docker Desktop"
    echo "2. Go to Extensions tab"
    echo "3. Find 'OpenWebUI + Model Runner' extension"
    echo "4. Click to open the extension"
    echo "5. Start chatting with models!"
else
    echo ""
    echo "❌ FAILED! Extension installation failed"
    echo "=================================================="
    echo "🔍 Check the error messages above"
    echo "📧 If you need help, check the Docker Desktop logs"
    echo ""
    echo "Troubleshooting:"
    echo "1. Ensure Docker Desktop is running"
    echo "2. Check that Docker Model Runner is enabled"
    echo "3. Verify metadata.json is valid"
    exit 1
fi

echo ""
echo "📋 Installation Summary:"
echo "- Original docker-compose.yaml backed up"
echo "- Simplified version created for extension"
echo "- Extension installed and ready to use"
echo ""
echo "To restore original docker-compose.yaml later:"
echo "ls docker-compose.backup-* | tail -1 | xargs -I {} cp {} docker-compose.yaml"
