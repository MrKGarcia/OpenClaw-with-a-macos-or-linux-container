# ══════════════════════════════════════════════════════════════════
#  OpenClaw — Instance Makefile Template (Linux host network by default;
#  macOS/Windows: see PLATFORM NOTES for Ollama URL + port mapping).
#  Copy this file, rename to "Makefile", and edit the CONFIGURATION section.
# ══════════════════════════════════════════════════════════════════
#
# ──────────────────────────────────────────────────────────────────
#     • QUICK START GUIDE:
# ──────────────────────────────────────────────────────────────────
#   1. Copy this file:    cp template_makefile Makefile
#   2. Edit CONFIGURATION (instance name, base path, MODEL, OLLAMA_BASE_URL)
#   3. make build         — Build the Docker image
#   4. make setup         — Run interactive setup (one-time)
#   5. make up            — Start the container
#   6. make dashboard     — Get the dashboard URL with auth token
#   7. Open the URL in your browser
#
# ──────────────────────────────────────────────────────────────────
#     • DAILY USAGE:
# ──────────────────────────────────────────────────────────────────
#   make up            — Start the container
#   make dashboard     — Get dashboard URL (bookmark this!)
#   make logs          — View live container logs
#   make down          — Stop the container
#
# ──────────────────────────────────────────────────────────────────
#     • REBUILD (after Makefile changes):
# ──────────────────────────────────────────────────────────────────
#   make down && make clean && make all
#
# ──────────────────────────────────────────────────────────────────
#     • PLATFORM NOTES (Docker networking ↔ Ollama):
# ──────────────────────────────────────────────────────────────────
#   Ollama listens on the host at port 11434 by default. The OpenClaw
#   container must reach that API — set OLLAMA_BASE_URL in CONFIGURATION
#   to a URL that resolves *from inside the container*.
#
#   Linux + --network host (default `up` recipe below):
#     OLLAMA_BASE_URL=http://127.0.0.1:11434  (same network namespace as host)
#
#   macOS / Windows (Docker Desktop) — use published ports, not host network:
#     In `up`, replace --network host with:
#       -p 18789:18789 -p 18791:18791
#     Set:
#     OLLAMA_BASE_URL=http://host.docker.internal:11434
#
#   Linux + bridge network (no host mode):
#     Often OLLAMA_BASE_URL=http://172.17.0.1:11434 (docker0) or your host LAN IP.
#
#   Ensure the model is available:  ollama pull <name>   (same name as MODEL)
#
# ══════════════════════════════════════════════════════════════════

# ══════════════════════════════════════════════════════════════════
#  CONFIGURATION — Edit these values for your setup
# ══════════════════════════════════════════════════════════════════

# ── EDIT THESE ────────────────────────────────────────────────────

INSTANCE_NAME      := <your-instance-name>           # e.g. mission-control, homelab, work
BASE_DIR           := <your-absolute-base-path>      # e.g. /home/youruser/openclaw-data

CONFIG_DIR_NAME    := .openclaw
PROJECTS_DIR_NAME  := projects
ARCHIVES_DIR_NAME  := archives
RESOURCES_DIR_NAME := resources
AREAS_DIR_NAME     := areas

# --- Ollama (local LLM API) ----------------------------------------
# MODEL is passed to the gateway; use a tag you have pulled on the host.
# Example:  ollama pull gemma3:12b   then   make up MODEL=gemma3:12b
MODEL              ?= <your-model>                   # e.g. gemma3:12b, llama3.1:8b, mistral
#
# OLLAMA_BASE_URL: base URL for Ollama’s HTTP API (default port 11434).
# Pick the line that matches your OS + the `docker run` flags in `up`:
OLLAMA_BASE_URL    := http://127.0.0.1:11434         # Linux + --network host (default `up`)
# OLLAMA_BASE_URL  := http://host.docker.internal:11434   # Docker Desktop (macOS/Windows); use -p 18789:18789 -p 18791:18791 in `up`
# OLLAMA_BASE_URL  := http://172.17.0.1:11434             # Linux, bridged docker0 (if not using host network)

# ══════════════════════════════════════════════════════════════════
#  DERIVED VALUES — Do not edit below this line
# ══════════════════════════════════════════════════════════════════

CONTAINER_NAME     := openclaw-$(INSTANCE_NAME)
IMAGE_NAME         := openclaw-$(INSTANCE_NAME):latest

CONFIG_DIR         := $(BASE_DIR)/$(CONFIG_DIR_NAME)
PROJECTS_DIR       := $(BASE_DIR)/$(PROJECTS_DIR_NAME)
ARCHIVES_DIR       := $(BASE_DIR)/$(ARCHIVES_DIR_NAME)
RESOURCES_DIR      := $(BASE_DIR)/$(RESOURCES_DIR_NAME)
AREAS_DIR          := $(BASE_DIR)/$(AREAS_DIR_NAME)

CONTAINER_CONFIG_DIR    := /home/node/$(CONFIG_DIR_NAME)
CONTAINER_PROJECTS_DIR  := /home/node/$(PROJECTS_DIR_NAME)
CONTAINER_ARCHIVES_DIR  := /home/node/$(ARCHIVES_DIR_NAME)
CONTAINER_RESOURCES_DIR := /home/node/$(RESOURCES_DIR_NAME)
CONTAINER_AREAS_DIR     := /home/node/$(AREAS_DIR_NAME)

.PHONY: all build up down clean logs shell setup dashboard tag

all: build up

## build: Build the OpenClaw Docker image
build:
	@echo "Building OpenClaw image: $(IMAGE_NAME)..."
	@printf '%s\n' \
		'FROM node:22' \
		'RUN npm i -g openclaw@latest' \
		'WORKDIR /home/node' \
		'USER node' \
		'CMD /usr/local/bin/openclaw gateway' \
		| docker build --no-cache -t $(IMAGE_NAME) -

## up: Create workspace dirs and start the OpenClaw container
## Default: --network host (Linux + OLLAMA_BASE_URL=http://127.0.0.1:11434).
## macOS/Windows: comment --network host, use -p 18789:18789 -p 18791:18791, set OLLAMA_BASE_URL to host.docker.internal (see CONFIGURATION).
up:
	@echo "Starting OpenClaw instance: $(CONTAINER_NAME)..."
	@mkdir -p $(CONFIG_DIR)
	@mkdir -p $(PROJECTS_DIR)
	@mkdir -p $(ARCHIVES_DIR)
	@mkdir -p $(RESOURCES_DIR)
	@mkdir -p $(AREAS_DIR)
	docker run -d \
		--name $(CONTAINER_NAME) \
		--network host \
		-v "$(CONFIG_DIR):$(CONTAINER_CONFIG_DIR)" \
		-v "$(PROJECTS_DIR):$(CONTAINER_PROJECTS_DIR)" \
		-v "$(ARCHIVES_DIR):$(CONTAINER_ARCHIVES_DIR)" \
		-v "$(RESOURCES_DIR):$(CONTAINER_RESOURCES_DIR)" \
		-v "$(AREAS_DIR):$(CONTAINER_AREAS_DIR)" \
		-e MODEL=$(MODEL) \
		-e OLLAMA_BASE_URL=$(OLLAMA_BASE_URL) \
		$(IMAGE_NAME)

## setup: Run interactive setup to configure OpenClaw (one-time)
setup:
	@echo "Running OpenClaw setup..."
	docker run -it --rm \
		-v "$(CONFIG_DIR):$(CONTAINER_CONFIG_DIR)" \
		$(IMAGE_NAME) \
		openclaw setup

## down: Stop and remove the OpenClaw container
down:
	@echo "Stopping $(CONTAINER_NAME)..."
	docker stop $(CONTAINER_NAME) 2>/dev/null || true
	docker rm   $(CONTAINER_NAME) 2>/dev/null || true

## clean: Remove the Docker image for this instance
clean:
	@echo "Removing image $(IMAGE_NAME)..."
	docker rmi $(IMAGE_NAME) 2>/dev/null || true

## logs: Follow live logs from the running container
logs:
	docker logs -f $(CONTAINER_NAME)

## shell: Open an interactive shell inside the running container
shell:
	docker exec -it $(CONTAINER_NAME) /bin/bash

## dashboard: Print the dashboard URL with authentication token
## Note: Bookmark this URL — the token persists in your config file
dashboard:
	@docker exec $(CONTAINER_NAME) openclaw dashboard 2>/dev/null | grep "token=" | head -1

## tag: Tag the current image with a version name
## Usage: make tag VERSION=<version-name>
## Example: make tag VERSION=v1.0
tag:
ifndef VERSION
	$(error VERSION is required. Usage: make tag VERSION=<version-name>)
endif
	@echo "Tagging $(IMAGE_NAME) as openclaw-$(INSTANCE_NAME):$(VERSION)..."
	docker tag $(IMAGE_NAME) openclaw-$(INSTANCE_NAME):$(VERSION)
	@echo "Tagged successfully. View with: docker images | grep openclaw-$(INSTANCE_NAME)"
