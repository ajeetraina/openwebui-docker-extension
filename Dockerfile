FROM ghcr.io/open-webui/open-webui:main

LABEL org.opencontainers.image.title="OpenWebUI + Model Runner" \
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
    && rm -rf /var/lib/apt/lists/*

# Remove Ollama references
RUN find /app -name "*ollama*" -type f -delete 2>/dev/null || true

# Create directories
RUN mkdir -p /app/model-runner /app/mcp /app/config

# Copy configuration files
COPY backend.env /app/backend.env
COPY docker-entrypoint.sh /app/docker-entrypoint.sh
RUN chmod +x /app/docker-entrypoint.sh

# Environment for Model Runner (based on aiwatch project)
ENV MODEL_RUNNER_ENABLED=true \
    MODEL_RUNNER_ENDPOINT=http://model-runner.docker.internal \
    BASE_URL=http://model-runner.docker.internal/engines/llama.cpp/v1/ \
    MODEL=ai/llama3.2:1B-Q8_0 \
    API_KEY=dockermodelrunner \
    OPENAI_API_BASE_URL=http://model-runner.docker.internal/engines/llama.cpp/v1 \
    OPENAI_API_KEY=dockermodelrunner \
    ENABLE_OLLAMA_API=false \
    ENABLE_OPENAI_API=true \
    ENABLE_MCP=true

USER 1000

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://model-runner.docker.internal/engines/llama.cpp/v1/models || exit 1

ENTRYPOINT ["/app/docker-entrypoint.sh"]

COPY docker-compose.yaml /docker-compose.yaml 
COPY metadata.json /metadata.json
COPY docker.svg /docker.svg
COPY ui /ui
