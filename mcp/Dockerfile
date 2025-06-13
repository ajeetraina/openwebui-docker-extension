FROM python:3.11-slim

RUN apt-get update && apt-get install -y \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

RUN useradd -m -u 1000 mcpuser && \
    chown -R mcpuser:mcpuser /app

COPY docker_mcp_server.py .
RUN chmod +x docker_mcp_server.py

RUN mkdir -p /app/data && \
    chown -R mcpuser:mcpuser /app/data

USER mcpuser

EXPOSE 8765

CMD ["python3", "docker_mcp_server.py"]
