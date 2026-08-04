.PHONY: help dev lint test build format typecheck analyze install hooks

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: ## Install all dependencies
	cd apps/web && npm install
	cd apps/mobile && flutter pub get
	@echo "✅ Run 'make hooks' to install git hooks"

hooks: ## Install git hooks
	git config core.hooksPath .githooks
	@chmod +x .githooks/pre-commit
	@echo "✅ Git hooks installed"

dev: ## Start web dev server
	cd apps/web && npm run dev

lint: ## Run all linters
	cd apps/web && npm run lint
	cd apps/mobile && flutter analyze --no-fatal-infos

test: ## Run all tests
	cd apps/web && npm run test
	cd apps/mobile && flutter test

test-web: ## Run web tests only
	cd apps/web && npm run test

test-mobile: ## Run mobile tests only
	cd apps/mobile && flutter test

build: ## Build web app
	cd apps/web && npm run build

format: ## Format all code
	cd apps/web && npm run format
	cd apps/mobile && dart format lib/

format-check: ## Check formatting (CI)
	cd apps/web && npm run format:check

typecheck: ## TypeScript type check
	cd apps/web && npm run typecheck

analyze: ## Flutter analyze
	cd apps/mobile && flutter analyze --no-fatal-infos

ci: lint typecheck test build ## Run full CI pipeline locally

clean: ## Clean build artifacts
	cd apps/web && rm -rf .next node_modules
	cd apps/mobile && flutter clean
	@echo "✅ Cleaned"
