SHELL := /usr/bin/env bash
POETRY_OK := $(shell type -P poetry)
PYTHON_OK := $(shell type -P python)
PYTHON_VERSION ?= $(shell python -V | cut -d' ' -f2)
PYTHON_REQUIRED := $(shell cat .python-version)
ROOT_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
POETRY_VIRTUALENVS_IN_PROJECT ?= true

help: ## The help text you're reading
	@grep --no-filename -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

apply: ## Apply terraform
	@poetry run python tools/environments/iac.py --environment ${TG_ENVIRONMENT} --apply

bandit: ## Run bandit
	@poetry run bandit -ll ./tools/**/*.py --exclude tools/environments/test.py

black: ## Run black
	@poetry run black ./tools/**/*.py

bootstrap_plan: ## Plan the bootstrapping of an environment
	@poetry run python tools/environments/iac.py --environment ${TG_ENVIRONMENT} --bootstrap

bootstrap_apply: ## Apply bootstrapping components
	@poetry run python tools/environments/iac.py --environment ${TG_ENVIRONMENT} --bootstrap --apply

check: ## Check build requirements
    ifeq ('$(PYTHON_OK)','')
	    $(error python interpreter: 'python' not found!)
    else
	    @echo Found Python.
    endif
    ifneq ('$(PYTHON_REQUIRED)','$(PYTHON_VERSION)')
	    $(error incorrect version of python found: '${PYTHON_VERSION}'. Expected '${PYTHON_REQUIRED}'!)
    else
	    @echo Correct Python version ${PYTHON_REQUIRED}.
    endif
    ifeq ('$(POETRY_OK)','')
	    $(error package 'poetry' not found!)
    else
	    @echo Found poetry
    endif

plan: ## Plan a terraform run
	@poetry run python tools/environments/iac.py --environment ${TG_ENVIRONMENT}

reset: ## Teardown tooling
	rm -rfv .venv

setup: check ## Setup virtualenv & dependencies using poetry
	@export POETRY_VIRTUALENVS_IN_PROJECT=$(POETRY_VIRTUALENVS_IN_PROJECT) && poetry run pip install --upgrade pip
	@poetry config --list
	@poetry install --no-root
	@poetry run pre-commit install

test: bandit black ## Run tests
	export PYTHONPATH="${PYTHONPATH}:`pwd`/tools/environments" && export TG_ENVIRONMENT=pytest && poetry run pytest -o log_cli=true -vvvv ./tools/environments/test.py
