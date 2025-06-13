FROM ghcr.io/open-webui/open-webui:main

LABEL org.opencontainers.image.title="OpenWebUI + Model Runner + MCP" \
    org.opencontainers.image.description="OpenWebUI with Docker Model Runner (llama.cpp) and MCP Integration" \
    org.opencontainers.image.vendor="Ajeet Singh Raina" \
    com.docker.desktop.extension.api.version="0.3.4" \
    com.docker.extension.categories="ai-ml,development" \
    com.docker.desktop.extension.icon="docker.svg"

USER root

RUN apt-get update && apt-get install -y \
    curl \
    jq \
    python3-pip \
    python3-venv \
    docker.io \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Remove Ollama references
RUN find /app -name "*ollama*" -type f -delete 2>/dev/null || true

# Create directories
RUN mkdir -p /app/model-runner /app/mcp /app/config /app/logs

# Install MCP dependencies
COPY mcp/requirements.txt /app/mcp/requirements.txt
RUN pip3 install --no-cache-dir -r /app/mcp/requirements.txt
RUN pip3 install --no-cache-dir mcpo

# Copy MCP files
COPY mcp/docker_mcp_tools.py /app/mcp/docker_mcp_tools.py
COPY mcp/entrypoint.sh /app/mcp/entrypoint.sh
RUN chmod +x /app/mcp/entrypoint.sh

# Copy configuration files
COPY backend.env /app/backend.env
COPY docker-entrypoint.sh /app/docker-entrypoint.sh
RUN chmod +x /app/docker-entrypoint.sh

# Copy supervisor configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Environment for Model Runner and MCP
ENV MODEL_RUNNER_ENABLED=true \
    MODEL_RUNNER_ENDPOINT=http://model-runner.docker.internal \
    BASE_URL=http://model-runner.docker.internal/engines/llama.cpp/v1/ \
    MODEL=ai/llama3.2:1B-Q8_0 \
    API_KEY=dockermodelrunner \
    OPENAI_API_BASE_URL=http://model-runner.docker.internal/engines/llama.cpp/v1 \
    OPENAI_API_KEY=dockermodelrunner \
    ENABLE_OLLAMA_API=false \
    ENABLE_OPENAI_API=true \
    ENABLE_MCP=true \
    ENABLE_OPENAPI_FUNCTIONS=true \
    OPENAPI_FUNCTIONS_URL=http://localhost:8001 \
    MCP_PORT=8001 \
    DOCKER_HOST=unix:///var/run/docker.sock

# Change ownership of app directory
RUN chown -R 1000:1000 /app

USER 1000

# Expose both OpenWebUI and MCP ports
EXPOSE 8080 8001

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080 || exit 1

# Use supervisor to run both services
ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Copy extension metadata files
COPY docker-compose.yaml /docker-compose.yaml 
COPY metadata.json /metadata.json
COPY docker.svg /docker.svg
COPY ui /ui
