SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
MAKEFLAGS += --warn-undefined-variables --no-builtin-rules
.DELETE_ON_ERROR:
.DEFAULT_GOAL := help

.PHONY: init-app prepare tools build test run pack clean help all

SHELLCHECK := shellcheck
SHFMT := shfmt
SRC_DIR := src
TEST_DIR := tests
OUT_DIR := out
DIST_DIR := dist
DOCS_DIR := docs

# Variables para la app de prueba
RELEASE ?= v1.0.0
PORT ?= 8080
MESSAGE ?= Hola, PC2!
VENV_DIR ?= venv
DOMAIN ?= pc2.local

# Variables para evaluación SLA
BUDGET_MS ?= 500
SAMPLES ?= 20
TARGET ?= pc2.local:8080
SLA_FILE ?= $(DOCS_DIR)/sla.csv
SLOW_COUNTER ?= 1
# Se lee de la primera columna de sla.csv, separando con comas
TARGETS := $(shell awk -F, 'NR>1 {print $$1}' $(SLA_FILE) | paste -sd "," -)

PY ?= python3
PYTHON := $(VENV_DIR)/bin/python
PIP := $(VENV_DIR)/bin/pip

export RELEASE PORT MESSAGE DOMAIN BUDGET_MS SAMPLES TARGET SLA_FILE TARGETS SLOW_COUNTER
export LC_ALL := C

all: tools test run ## Verifica herramientas, corre tests y ejecuta el sistema

tools:
	@command -v $(PY) >/dev/null || { echo "Falta $(PY)"; exit 1; }
	@command -v curl >/dev/null || { echo "Falta curl"; exit 1; }
	@command -v getent >/dev/null || { echo "Falta getent"; exit 1; }
	@command -v ss >/dev/null || { echo "Falta ss"; exit 1; }
	@command -v bats >/dev/null || { echo "Falta bats"; exit 1; }
	@command -v grep >/dev/null || { echo "Falta grep"; exit 1; }
	@command -v sort >/dev/null || { echo "Falta sort"; exit 1; }
	@command -v awk >/dev/null || { echo "Falta awk"; exit 1; }
	@command -v tar >/dev/null || { echo "Falta tar"; exit 1; }
	@tar --version 2>/dev/null | grep -q 'GNU tar' || { echo "Se requiere GNU tar"; exit 1; }
	@echo "[INFO] Todas las herramientas necesarias están instaladas."

build: tools ## Preparar artefactos intermedios sin ejecutar
	@echo "[BUILD] Preparando entorno..."
	@mkdir -p $(OUT_DIR) $(DIST_DIR)
	@chmod +x $(SRC_DIR)/*.sh
	@echo "[BUILD] Validando configuración SLA..."
	@test -f $(SLA_FILE) || { echo "Error: falta archivo $(SLA_FILE)"; exit 5; }
	@test -s $(SLA_FILE) || { echo "Error: $(SLA_FILE) está vacío"; exit 5; }
	@echo "[BUILD] Validando que hay al menos 1 endpoint en SLA..."
	@[ $$(tail -n +2 $(SLA_FILE) | wc -l) -gt 0 ] || { echo "Error: SLA sin endpoints"; exit 5; }
	@echo "[BUILD] Build completado. Sistema listo para 'make run'"

test:
	@bats $(TEST_DIR)/*.bats

run: ## Consulta cada URL con curl, registra tiempos, códigos de estado y headers y evalúa cumplimiento
	@mkdir -p $(OUT_DIR)
	@chmod +x $(SRC_DIR)/*.sh
	@echo "[INFO] Iniciando pruebas DNS, HTTP y sockets..."
	@$(SRC_DIR)/basic_checks.sh
	@echo "[INFO] Recolectando de métricas..."
	@echo "$(SLA_FILE)"
	@echo "${TARGETS}" 
	@$(SRC_DIR)/collect_metrics.sh 1>/dev/null
	@echo "[INFO] Realizando evaluación SLA..."
	@$(SRC_DIR)/evaluate_metrics.sh || true

pack: build ## Crear paquete reproducible en dist/
	@echo "[PACK] Creando paquete $(RELEASE)..."
	@tar czf $(DIST_DIR)/proyecto-sla-$(RELEASE).tar.gz \
		--exclude='out' \
		--exclude='dist' \
		--exclude='__pycache__' \
		--exclude='*.pyc' \
		--exclude='venv' \
		--exclude='.git' \
		--transform 's,^,proyecto-sla-$(RELEASE)/,' \
		src/ tests/ docs/ Makefile README.md requirements.txt app.py 2>/dev/null || true
	@echo "[PACK] ✓ Paquete creado: $(DIST_DIR)/proyecto-sla-$(RELEASE).tar.gz"
	@ls -lh $(DIST_DIR)/proyecto-sla-$(RELEASE).tar.gz

clean: ## Limpiar archivos generados
	rm -rf $(OUT_DIR) $(DIST_DIR)

help:
	@grep -E '^[a-zA-Z0-9._-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

init-app: prepare hosts-setup ## Inicializa aplicación Flask para pruebas
	@$(PYTHON) app.py

prepare: $(VENV_DIR) ## Crear entorno virtual e instala dependencias de la app de pruebas
	@$(PIP) install --upgrade pip 1>/dev/null 2>&1
	@$(PIP) install -r requirements.txt 1>/dev/null 2>&1

hosts-setup: ## Añadir '127.0.0.1 $(DOMAIN)' a hosts (Linux/macOS) o mostrar comando para Windows
	@if [ -f /etc/hosts ]; then \
		if ! grep -qE "127\.0\.0\.1\s+$(DOMAIN)" /etc/hosts; then \
			echo "Agregando $(DOMAIN) a /etc/hosts"; \
			echo "127.0.0.1 $(DOMAIN)" | sudo tee -a /etc/hosts; \
		else echo "$(DOMAIN) ya está presente en /etc/hosts"; fi; \
	else echo "/etc/hosts no encontrado."; \
	fi

$(VENV_DIR):
	@$(PY) -m venv $(VENV_DIR) 1>/dev/null 2>&1
	@echo "Entorno virtual creado en '$(VENV_DIR)'"