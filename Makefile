# Makefile for building and running the project.
# The purpose of this Makefile is to avoid developers having to remember
# project-specific commands for building, running, etc.  Recipes longer
# than one or two lines should live in script files of their own in the
# bin/ directory.

PORT ?= 3001

all: check

setup:
	bin/setup

check: lint test

lint:
	@echo "--- rubocop ---"
ifdef JUNIT_OUTPUT
	bundle exec rubocop --parallel --format progress --format junit --out rubocop.xml --display-only-failed
else
	bundle exec rubocop --parallel
endif
	@echo "--- eslint ---"
	yarn lint

test:
	bundle exec rspec

run:
	foreman start -p $(PORT)

.PHONY: setup all lint run test check
