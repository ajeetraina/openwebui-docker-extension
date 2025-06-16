#!/bin/bash
# Quick one-liner fix (if you prefer minimal approach)

echo "🚀 Quick Fix: Commenting out problematic line and rebuilding..." && \
sed -i 's/^RUN chown -R 1000:1000 \/app$/# RUN chown -R 1000:1000 \/app/' Dockerfile && \
docker extension rm openwebui-model-runner 2>/dev/null || true && \
docker stop openwebui-model-runner 2>/dev/null || true && \
docker rm openwebui-model-runner 2>/dev/null || true && \
docker buildx build --no-cache -t openwebui-model-runner:latest . --load && \
docker extension install openwebui-model-runner:latest && \
echo "✅ Done! Check logs: docker logs openwebui-model-runner"
