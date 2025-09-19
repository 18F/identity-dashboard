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

lint: lint_log_events lint_log_events_sorted
	@echo "--- rubocop ---"
ifdef JUNIT_OUTPUT
	bundle exec rubocop --parallel --format progress --format junit --out rubocop.xml --display-only-failed
else
	bundle exec rubocop --parallel
endif
	@echo "--- eslint ---"
	npm run lint

lint_database_schema_files: ## Checks that database schema files have not changed
	(! git diff --name-only | grep db/schema.rb) || (echo "Error: db/schema.rb does not match after running migrations"; exit 1)

test:
	bundle exec rspec

test_basic:
	COVERAGE=true bundle exec rspec --exclude-pattern "spec/features/accessibility/**/*_spec.rb"

run:
	foreman start -p $(PORT)

.PHONY: setup all lint lint_database_schema_files run test check

doc:
	bin/yardoc \
		--fail-on-warning

lint_log_events: doc ## Checks that all methods on `LogEvents` are documented
	bundle exec ruby lib/events_documenter.rb --class-name="LogEvents" --check --skip-extra-params 

lint_log_events_sorted:
	(awk '/^  def/; /^  private/ {exit}' app/services/log_events.rb | LC_COLLATE='C.UTF-8' sort -c) || \
		(echo '\033[1;31mError: methods in log_events.rb are not sorted alphabetically\033[0m' && exit 1)
