APP = dns-helper
VERSION ?= 0.0.2
BUILD_TIME = $(shell date -u '+%Y-%m-%d_%H:%M:%S')
LDFLAGS = -ldflags "-X main.version=$(VERSION) -X main.buildTime=$(BUILD_TIME)"

.PHONY: help build clean test run release install lint

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build the application
	@echo "Building $(APP) version $(VERSION)..."
	go build $(LDFLAGS) -o bin/$(APP) ./cmd/dns-helper

clean: ## Clean build artifacts
	rm -rf bin/
	go clean -cache

test: ## Run all tests
	go test -v ./... -count=1

test-short: ## Run tests with short flag
	go test -v ./... -short -count=1

test-race: ## Run tests with race detection
	go test -race ./... -count=1

test-coverage: ## Run tests with coverage report
	go test -v ./... -coverprofile=coverage.out -covermode=atomic
	go tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report generated: coverage.html"

test-benchmark: ## Run benchmark tests
	go test -v ./... -bench=. -benchmem

test-integration: ## Run integration tests only
	go test -v ./internal/integration_test.go ./internal/... -run TestIntegration

test-unit: ## Run unit tests only (skip integration)
	go test -v ./... -run '^(Test|Benchmark)' -skip TestIntegration

test-verbose: ## Run tests with verbose output
	go test -v ./... -count=1 -test.v

test-debug: ## Run tests with debug output
	DNS_HELPER_DEBUG=true go test -v ./... -count=1

test-skip-network: ## Run tests skipping network tests
	DNS_HELPER_SKIP_NETWORK=true go test -v ./... -count=1

test-skip-slow: ## Run tests skipping slow tests
	DNS_HELPER_SKIP_SLOW=true go test -v ./... -count=1

test-timeout: ## Run tests with custom timeout
	DNS_HELPER_TIMEOUT=60s go test -v ./... -count=1

test-all: ## Run all test variations
	@echo "Running all test variations..."
	$(MAKE) test
	$(MAKE) test-race
	$(MAKE) test-coverage
	$(MAKE) test-benchmark
	$(MAKE) test-skip-network
	$(MAKE) test-skip-slow

run: ## Run the application
	go run $(LDFLAGS) ./cmd/dns-helper --help

install: ## Install the application
	go install $(LDFLAGS) ./cmd/dns-helper

lint: ## Run linters
	golangci-lint run

lint-fix: ## Run linters with auto-fix
	golangci-lint run --fix

release: ## Create a release using GoReleaser
	goreleaser release --clean

release-snapshot: ## Create a snapshot release
	goreleaser release --snapshot --clean

deps: ## Download dependencies
	go mod download
	go mod verify

fmt: ## Format code
	go fmt ./...

vet: ## Run go vet
	go vet ./...

check: ## Run all checks (fmt, vet, lint, test)
	@echo "Running all checks..."
	$(MAKE) fmt
	$(MAKE) vet
	$(MAKE) lint
	$(MAKE) test

pre-commit: ## Run pre-commit checks
	@echo "Running pre-commit checks..."
	$(MAKE) fmt
	$(MAKE) vet
	$(MAKE) lint
	$(MAKE) test-short

ci: ## Run CI checks (used by GitHub Actions)
	@echo "Running CI checks..."
	$(MAKE) deps
	$(MAKE) check
	$(MAKE) test-coverage
	$(MAKE) test-race
