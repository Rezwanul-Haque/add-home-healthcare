# ADD Home Healthcare — static site build & deploy
#
#   make            show this help
#   make build      render site/ -> dist/ with the configured domain
#   make serve      build and preview at http://localhost:8080
#   make check      sanity-check the build (placeholders, links, files)
#   make deploy     build and push dist/ to the gh-pages branch
#   make clean      remove dist/
#
# Change the domain in config.mk (or on the command line, see below).

include config.mk

SRC_DIR   := site
DIST_DIR  := dist
SITE_URL  := $(SCHEME)://$(DOMAIN)$(BASE_PATH)
LASTMOD   := $(shell date -u +%Y-%m-%d)
PORT      ?= 8090

# Files that contain placeholders and must be rendered, not copied.
TEMPLATES := index.html 404.html robots.txt sitemap.xml

.DEFAULT_GOAL := help
.PHONY: help build check serve deploy clean config

help: ## Show this help
	@echo ""
	@echo "ADD Home Healthcare — site tasks"
	@echo ""
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' Makefile | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[1m%-10s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Current target URL: $(SITE_URL)"
	@echo "Override per run:   make build DOMAIN=example.com BASE_PATH=/"
	@echo "                    make build DOMAIN=user.github.io BASE_PATH=/repo/ USE_CNAME=0"
	@echo ""

config: ## Print the resolved configuration
	@echo "DOMAIN        = $(DOMAIN)"
	@echo "BASE_PATH     = $(BASE_PATH)"
	@echo "SCHEME        = $(SCHEME)"
	@echo "SITE_URL      = $(SITE_URL)"
	@echo "USE_CNAME     = $(USE_CNAME)"
	@echo "DEPLOY_BRANCH = $(DEPLOY_BRANCH)"
	@echo "REPO_URL      = $(REPO_URL)"

build: clean ## Render site/ into dist/ with the configured domain
	@echo "Building for $(SITE_URL)"
	@mkdir -p $(DIST_DIR)
	@cp -R $(SRC_DIR)/. $(DIST_DIR)/
	@for f in $(TEMPLATES); do \
	  sed -e 's#__SITE_URL__#$(SITE_URL)#g' \
	      -e 's#__BASE_PATH__#$(BASE_PATH)#g' \
	      -e 's#__LASTMOD__#$(LASTMOD)#g' \
	      $(SRC_DIR)/$$f > $(DIST_DIR)/$$f; \
	done
	@touch $(DIST_DIR)/.nojekyll
	@if [ "$(USE_CNAME)" = "1" ]; then echo "$(DOMAIN)" > $(DIST_DIR)/CNAME; echo "CNAME -> $(DOMAIN)"; else rm -f $(DIST_DIR)/CNAME; fi
	@$(MAKE) --no-print-directory check
	@echo "Done: $(DIST_DIR)/"

check: ## Verify the build has no leftover placeholders and all local assets exist
	@test -d $(DIST_DIR) || { echo "dist/ missing — run 'make build' first"; exit 1; }
	@if grep -rl '__SITE_URL__\|__BASE_PATH__\|__LASTMOD__' $(DIST_DIR) >/dev/null; then \
	  echo "ERROR: unreplaced placeholders in:"; grep -rl '__SITE_URL__\|__BASE_PATH__\|__LASTMOD__' $(DIST_DIR); exit 1; fi
	@missing=0; for ref in $$(grep -oE '(src|href)="\./assets/[^"]+"' $(DIST_DIR)/index.html | sed -E 's/.*"\.\/(.*)"/\1/' | sort -u); do \
	  [ -f "$(DIST_DIR)/$$ref" ] || { echo "ERROR: missing asset $$ref"; missing=1; }; done; [ $$missing -eq 0 ]
	@if grep -q 'YOUR_FORM_ID' $(DIST_DIR)/index.html; then echo "WARNING: contact form action still points at YOUR_FORM_ID"; fi
	@if grep -q 'TODO' $(DIST_DIR)/index.html; then echo "NOTE: $$(grep -c TODO $(DIST_DIR)/index.html) TODO comment(s) remain in index.html"; fi
	@echo "check: OK"

serve: build ## Build and preview locally
	@echo "Serving $(DIST_DIR)/ at http://localhost:$(PORT)  (Ctrl+C to stop)"
	@cd $(DIST_DIR) && python3 -m http.server $(PORT)

deploy: build ## Build and force-push dist/ to the $(DEPLOY_BRANCH) branch
	@test -n "$(REPO_URL)" || { echo "REPO_URL is empty — set it in config.mk or run: make deploy REPO_URL=git@github.com:user/repo.git"; exit 1; }
	@echo "Deploying to $(REPO_URL) [$(DEPLOY_BRANCH)]"
	@remote="$(REPO_URL)"; case "$$remote" in /*|*://*|*@*:*) ;; *) remote="$$(cd "$$(dirname "$$remote")" && pwd)/$$(basename "$$remote")";; esac; \
	  cd $(DIST_DIR) && rm -rf .git \
	  && git init -q \
	  && git checkout -q -b $(DEPLOY_BRANCH) \
	  && git add -A \
	  && git -c user.name="deploy" -c user.email="deploy@localhost" commit -q -m "Deploy $(LASTMOD) for $(SITE_URL)" \
	  && git push -f "$$remote" $(DEPLOY_BRANCH) \
	  && rm -rf .git
	@echo "Published. In GitHub: Settings → Pages → Source: branch '$(DEPLOY_BRANCH)', folder '/ (root)'."

clean: ## Remove dist/
	@rm -rf $(DIST_DIR)
