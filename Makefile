.PHONY: help build up down shell init-working-group doctor checkpoint demo smoke-test test-working-group test-layout test-secrets workspace-smoke-test github-smoke-test

help:
	@echo "OASIS Hermes commands"
	@echo
	@echo "  make build               Build the local container image"
	@echo "  make up                  Start the local compose stack"
	@echo "  make down                Stop the local compose stack"
	@echo "  make shell               Open a shell in the Hermes container"
	@echo "  make init-working-group  Initialize the local workspace scaffold"
	@echo "  make doctor              Run safe local health checks"
	@echo "  make checkpoint          Write a local workspace checkpoint"
	@echo "  make demo                Run the deterministic environmental demo"
	@echo "  make smoke-test          Run lightweight operational validation"
	@echo "  make workspace-smoke-test Validate the workspace file manager"
	@echo "  make github-smoke-test   Validate the GitHub repository manager"
	@echo "  make test-working-group  Validate the seeded working-group scaffold"
	@echo "  make test-layout         Validate the /data layout scaffold"
	@echo "  make test-secrets        Check secret hygiene helpers"

build:
	@docker compose build

up:
	@docker compose up

down:
	@docker compose down

shell:
	@docker compose run --rm hermes-local bash

init-working-group:
	@scripts/init_working_group.sh

doctor:
	@scripts/doctor.sh

checkpoint:
	@scripts/checkpoint.sh

demo:
	@python3 scripts/demo_environmental_workflow.py --workspace "$${HERMES_WORKSPACE_DIR:-$${WORKSPACE_DIR:-workspace}}"

smoke-test:
	@scripts/smoke_test.sh

workspace-smoke-test:
	@scripts/smoke_test_workspace.sh

github-smoke-test:
	@scripts/smoke_test_github_manager.sh

test-working-group:
	@scripts/test-working-group.sh

test-layout:
	@scripts/test-hermes-layout.sh

test-secrets:
	@scripts/test-secrets.sh
