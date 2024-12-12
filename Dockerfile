FROM alpine
LABEL org.opencontainers.image.title="OpenWebUI" \
    org.opencontainers.image.description="Open WebUI Extension for Docker Desktop" \
    org.opencontainers.image.vendor="Ajeet Singh Raina" \
    com.docker.desktop.extension.api.version="0.3.4" \
    com.docker.extension.screenshots="[ \
    {\"url\": \"https://raw.githubusercontent.com/collabnix/openwebui-docker-extension/main/ollama.png\", \"alt\": \"Screenshot\"} \
    ]" \
    com.docker.extension.categories="ai-ml" \
    com.docker.desktop.extension.icon="https://raw.githubusercontent.com/collabnix/openwebui-docker-extension/main/ollama.svg"  \
    com.docker.extension.detailed-description="Open WebUI is a self-hosted, feature-rich, and user-friendly interface designed for managing and interacting with large language models (LLMs). It operates entirely offline and provides extensive support for various LLM runners, including Ollama and OpenAI-compatible APIs. With its focus on flexibility and ease of use, Open WebUI caters to developers, administrators, and hobbyists looking to enhance their LLM workflows. " \
    com.docker.extension.publisher-url='[{"title":"GitHub", "url":"https://github.com/collabnix/openwebui-docker-extension/"}]' \
    com.docker.extension.additional-urls='[{"title":"GitHub","url":"https://github.com/collabnix/openwebui-docker-extension/"}]' \
    com.docker.extension.changelog=""

COPY docker-compose.yaml .
COPY metadata.json .
COPY ollama.svg .
COPY ui ui
