SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
MAKEFLAGS += --warn-undefined-variables --no-builtin-rules
.DELETE_ON_ERROR:
.DEFAULT_GOAL := help

.PHONY: init-app prepare tools build test run pack clean help

# Variables para la app de prueba
RELEASE ?= "v1.0.0"
PORT ?= 8080
MESSAGE ?= "Hola, PC2!"
VENV_DIR ?= venv

# Variables para evaluación SLA
TARGET ?= "localhost:8080"
SLA_FILE ?= sla.csv

PY ?= python3
PYTHON := $(VENV_DIR)/bin/python
PIP := $(VENV_DIR)/bin/pip

SHELLCHECK := shellcheck
SHFMT := shfmt
SRC_DIR := src
TEST_DIR := tests
OUT_DIR := out
DIST_DIR := dist

tools:
	@command -v $(PY) >/dev/null || { echo "Falta $(PY)"; exit 1; }
	@command -v curl >/dev/null || { echo "Falta curl"; exit 1; }
	@command -v bats >/dev/null || { echo "Falta bats"; exit 1; }
	@command -v grep >/dev/null || { echo "Falta grep"; exit 1; }
	@command -v sort >/dev/null || { echo "Falta sort"; exit 1; }
	@command -v awk >/dev/null || { echo "Falta awk"; exit 1; }
	@command -v tar >/dev/null || { echo "Falta tar"; exit 1; }
	@tar --version 2>/dev/null | grep -q 'GNU tar' || { echo "Se requiere GNU tar"; exit 1; }
	@echo "Todas las herramientas necesarias están instaladas."

build:
	echo TODO

test:
	echo TODO

run: ## Consulta cada URL con curl, registra tiempos, códigos de estado y headers y evalúa cumplimiento
	echo TODO

pack:
	echo TODO

clean: ## Limpiar archivos generados
	rm -rf $(OUT_DIR) $(DIST_DIR)

help:
	@grep -E '^[a-zA-Z0-9._-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

init-app: prepare ## Inicializa aplicación Flask para pruebas
	@$(PYTHON) app.py

prepare: $(VENV_DIR) ## Crear entorno virtual e instala dependencias de la app de pruebas
	@$(PIP) install --upgrade pip 1>/dev/null 2>&1
	@$(PIP) install -r requirements.txt 1>/dev/null 2>&1

$(VENV_DIR):
	@$(PY) -m venv $(VENV_DIR) 1>/dev/null 2>&1
	@echo "Entorno virtual creado en '$(VENV_DIR)'"