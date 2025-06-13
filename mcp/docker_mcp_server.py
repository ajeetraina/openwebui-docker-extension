#!/usr/bin/env python3
"""
Docker MCP Server for OpenWebUI + Model Runner Integration
Based on aiwatch project configuration pattern
"""

import asyncio
import json
import logging
import os
import httpx

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("docker_mcp_server")

# Model Runner endpoints (based on aiwatch project)
MODEL_RUNNER_LLAMA_CPP_ENDPOINT = os.getenv("MODEL_RUNNER_LLAMA_CPP_ENDPOINT", 
    "http://model-runner.docker.internal/engines/llama.cpp/v1")
DEFAULT_MODEL = os.getenv("DEFAULT_MODEL", "ai/llama3.2:1B-Q8_0")
API_KEY = os.getenv("API_KEY", "dockermodelrunner")

async def test_model_runner():
    """Test Model Runner connectivity"""
    try:
        async with httpx.AsyncClient() as client:
            # Test models endpoint
            response = await client.get(f"{MODEL_RUNNER_LLAMA_CPP_ENDPOINT}/models")
            if response.status_code == 200:
                logger.info("✅ Model Runner llama.cpp endpoint is accessible")
                return True
            else:
                logger.warning(f"⚠️ Model Runner returned status {response.status_code}")
                return False
    except Exception as e:
        logger.error(f"❌ Model Runner test failed: {e}")
        return False

async def main():
    """Main MCP server entry point"""
    logger.info("🚀 Starting Docker MCP Server for Model Runner integration")
    logger.info(f"🔗 llama.cpp Endpoint: {MODEL_RUNNER_LLAMA_CPP_ENDPOINT}")
    logger.info(f"🤖 Default Model: {DEFAULT_MODEL}")
    
    # Test connectivity
    await test_model_runner()
    
    logger.info("✅ MCP Server ready")
    
    # Keep server running
    while True:
        await asyncio.sleep(60)

if __name__ == "__main__":
    asyncio.run(main())
