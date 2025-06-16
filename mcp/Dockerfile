FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    docker.io \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements and install Python dependencies
COPY mcp/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Install mcpo (MCP-to-OpenAPI proxy)
RUN pip install mcpo

# Create mcpuser for security
RUN useradd -m -u 1000 mcpuser && \
    chown -R mcpuser:mcpuser /app

# Copy MCP server and configuration
COPY mcp/docker_mcp_tools.py .
COPY mcp/entrypoint.sh .
RUN chmod +x docker_mcp_tools.py entrypoint.sh

# Create data directory
RUN mkdir -p /app/data && \
    chown -R mcpuser:mcpuser /app/data

# Add mcpuser to docker group for Docker socket access
RUN usermod -aG docker mcpuser

# Create user with ID 1000
RUN useradd -u 1000 -m openwebui

# Or create group and user
RUN groupadd -g 1000 openwebui && \
    useradd -u 1000 -g openwebui -m openwebui

# Expose mcpo proxy port
EXPOSE 8001

# Use entrypoint script to start mcpo with our MCP server
CMD ["./entrypoint.sh"]
