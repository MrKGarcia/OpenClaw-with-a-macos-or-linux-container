# ══════════════════════════════════════════════════════════════════
#  OpenClaw — Instance Makefile Template (Linux)
#  Copy this file, rename to "Makefile", and edit the CONFIGURATION section.
# ══════════════════════════════════════════════════════════════════
#
# ──────────────────────────────────────────────────────────────────
#     • QUICK START GUIDE:
# ──────────────────────────────────────────────────────────────────
#   1. Copy this file:    cp template_makefile Makefile
#   2. Edit CONFIGURATION section below (instance name, base path, model)
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
#     • PLATFORM NOTES:
# ──────────────────────────────────────────────────────────────────
#   This template is configured for LINUX.
#   For macOS: Change --network host to -p 18789:18789 -p 18791:18791
#              Change OLLAMA_BASE_URL to http://host.docker.internal:11434
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

MODEL              ?= <your-model>                   # e.g. gemma4:31b, llama3:70b, gpt-4
OLLAMA_BASE_URL    := http://localhost:11434         # Linux: localhost or 172.17.0.1

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
## Note: Uses --network host for Linux. For macOS, use -p 18789:18789 -p 18791:18791 instead. line 101 below. 
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
