EXTENSION_NAME := openwebui-model-runner
IMAGE_NAME := $(EXTENSION_NAME):latest

.PHONY: help
help:
	@echo "OpenWebUI + Docker Model Runner Extension (aiwatch pattern)"
	@echo "=========================================================="
	@echo "build-extension       Build the extension"
	@echo "install-extension     Install to Docker Desktop"
	@echo "dev-up               Start development environment" 
	@echo "models-pull          Pull recommended models"
	@echo "test-model-runner    Test Model Runner connectivity"
	@echo "status               Show system status"
	@echo "clean                Clean up"

.PHONY: build-extension
build-extension:
	@echo "🚀 Building OpenWebUI + Model Runner extension..."
	docker build -t $(IMAGE_NAME) .

.PHONY: install-extension
install-extension: build-extension
	@echo "📦 Installing extension to Docker Desktop..."
	docker extension rm $(EXTENSION_NAME) 2>/dev/null || true
	docker extension install $(IMAGE_NAME) --force
	@echo "✅ Extension installed! Check Docker Desktop Extensions tab."

.PHONY: dev-up
dev-up:
	@echo "🔧 Starting development environment..."
	docker-compose up -d

.PHONY: models-pull
models-pull:
	@echo "📦 Pulling recommended models for Model Runner..."
	@echo "🤖 Pulling ai/llama3.2:1B-Q8_0 (default model)..."
	docker model pull ai/llama3.2:1B-Q8_0 || echo "⚠️ Failed to pull model"
	@echo "📦 Pulling additional models..."
	docker model pull ai/gemma3:4B-F16 || echo "⚠️ Failed to pull gemma3"
	@echo "✅ Model pulling completed"
	@make models-list

.PHONY: models-list
models-list:
	@echo "📋 Available models:"
	docker model ls || echo "⚠️ Docker Model Runner not available"

.PHONY: test-model-runner
test-model-runner:
	@echo "🧪 Testing Model Runner connectivity..."
	@echo "🔗 Testing llama.cpp endpoint..."
	curl -s http://model-runner.docker.internal/engines/llama.cpp/v1/models || echo "❌ llama.cpp endpoint not accessible"
	@echo "🔗 Testing models endpoint..."
	curl -s http://model-runner.docker.internal/v1/models || echo "❌ models endpoint not accessible"
	@echo "✅ Model Runner test completed"

.PHONY: status
status:
	@echo "📊 System Status"
	@echo "==============="
	@echo "Docker Model Runner:"
	@curl -s http://model-runner.docker.internal/v1/models > /dev/null && echo "  ✅ Connected" || echo "  ❌ Not available"
	@echo "Extension:"
	@docker extension ls | grep -q $(EXTENSION_NAME) && echo "  ✅ Installed" || echo "  ⚠️ Not installed"
	@echo "Development Environment:"
	@docker-compose ps --services --filter "status=running" | wc -l | awk '{if($$1>0) print "  ✅ Running ("$$1" services)"; else print "  ⚠️ Stopped"}'

.PHONY: clean
clean:
	@echo "🧹 Cleaning up..."
	docker-compose down -v 2>/dev/null || true
	docker image rm $(IMAGE_NAME) 2>/dev/null || true
	docker system prune -f --filter label=openwebui.extension=true 2>/dev/null || true
