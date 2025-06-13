#!/bin/bash

set -e

echo "🚀 Starting OpenWebUI with Docker Model Runner (llama.cpp) + MCP Integration..."

# Model Runner endpoints (based on aiwatch project)
MODEL_RUNNER_LLAMA_CPP_ENDPOINT="${MODEL_RUNNER_ENDPOINT:-http://model-runner.docker.internal}/engines/llama.cpp/v1"
MODEL_RUNNER_MODELS_ENDPOINT="${MODEL_RUNNER_ENDPOINT:-http://model-runner.docker.internal}/v1/models"
COMPOSE_LLM_ENDPOINT="http://llm:11434"

echo "🔥 OpenWebUI + Docker Model Runner (llama.cpp) + MCP Toolkit"
echo "============================================================"
echo "🎯 Using configuration pattern from aiwatch project"
echo "🔗 llama.cpp Endpoint: ${MODEL_RUNNER_LLAMA_CPP_ENDPOINT}"
echo "🔗 Models Endpoint: ${MODEL_RUNNER_MODELS_ENDPOINT}"
echo "🔗 Compose LLM: ${COMPOSE_LLM_ENDPOINT}"
echo "🤖 Default Model: ${MODEL:-ai/llama3.2:1B-Q8_0}"

# Wait for Model Runner
echo "⏳ Waiting for Docker Model Runner..."
for i in {1..30}; do
    if curl -s -f "${MODEL_RUNNER_MODELS_ENDPOINT}" > /dev/null 2>&1; then
        echo "✅ Docker Model Runner is available!"
        break
    elif curl -s -f "${COMPOSE_LLM_ENDPOINT}/api/tags" > /dev/null 2>&1; then
        echo "✅ Docker Compose model provider is available!"
        break
    fi
    echo "🔄 Attempt $i/30: Waiting for model services..."
    sleep 2
done

# Configure environment
export ENABLE_OLLAMA_API=false
export ENABLE_OPENAI_API=true
export OPENAI_API_BASE_URL="${MODEL_RUNNER_LLAMA_CPP_ENDPOINT}"
export OPENAI_API_KEY="dockermodelrunner"
export WEBUI_NAME="OpenWebUI + Model Runner"
export ENABLE_MCP=true

# Start OpenWebUI
echo "🚀 Starting OpenWebUI with Model Runner integration..."
exec python3 -m backend.main
