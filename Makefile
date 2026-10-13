SRC_DIR := src
OUT_DIR := out
SOURCES := $(wildcard $(SRC_DIR)/*.txt)
OUTPUTS := $(patsubst $(SRC_DIR)/%.txt,$(OUT_DIR)/%.txt,$(SOURCES))

.PHONY: all check build test clean ci help

all: test ## Build and test everything

check: ## Check source files
	@if [ ! -d "$(SRC_DIR)" ] || [ -z "$(SOURCES)" ]; then \
		echo "ERROR: no .txt files found in $(SRC_DIR)"; \
		exit 1; \
	fi
	@echo "Found $$(echo "$(SOURCES)" | wc -w) source file(s)"

build: $(OUTPUTS) ## Build all outputs

$(OUT_DIR)/%.txt: $(SRC_DIR)/%.txt | $(OUT_DIR)
	@echo "  BUILD $< -> $@"
	@tr '[:lower:]' '[:upper:]' < $< > $@

$(OUT_DIR):
	mkdir -p $(OUT_DIR)

test: build ## Test all outputs
	@if grep -l '[a-z]' $(OUTPUTS) >/dev/null 2>&1; then \
		echo "TEST FAILED: lowercase characters remain"; exit 1; \
	fi
	@echo "TEST PASSED"

clean: ## Remove output directory
	rm -rf $(OUT_DIR)

ci: clean check test ## Clean, check, build and test

help: ## List available targets
	@grep -E '^[a-zA-Z0-9_-]+:.*##' Makefile | sed 's/:.*##/: /'

out/report.txt: $(OUTPUTS)
	@echo "Report generated: $$(date)" > $@
	@echo "" >> $@
	@for file in $(OUTPUTS); do \
		echo "$$file: $$(wc -l < $$file) lines" >> $@; \
	done

count: build ## report source files and built words
	@ls -1 $(SRC_DIR)/*.txt | wc -l
	@wc -w $(OUTPUTS) | tail -1

# count: see section 5 of the README
# OUTPUTS is set by the wildcard above
# run 'make help' for all targets
