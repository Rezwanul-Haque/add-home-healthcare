# ---------------------------------------------------------------
# Site configuration — the only file you need to edit to change
# where the site lives. Every value can also be overridden on the
# command line, e.g.  make build DOMAIN=addhomehealthcare.org
# ---------------------------------------------------------------

# Public hostname of the site (no scheme, no trailing slash).
#   Custom domain:        www.addhomehealthcare.com
#   Plain GitHub Pages:   <username>.github.io
DOMAIN      ?= www.addhomehealthcare.com

# Path under the domain where the site is served.
#   Custom domain or user/organization site:   /
#   Project site (https://<user>.github.io/<repo>/):   /<repo>/
BASE_PATH   ?= /

# Scheme (GitHub Pages always serves https once "Enforce HTTPS" is on).
SCHEME      ?= https

# Write a CNAME file into the build so GitHub Pages keeps the custom
# domain after each deploy. Set to 0 when deploying to <user>.github.io.
USE_CNAME   ?= 1

# Branch GitHub Pages serves from (Settings → Pages → Source).
DEPLOY_BRANCH ?= gh-pages

# Git remote to push the built site to. Defaults to this repo's origin.
REPO_URL    ?= $(shell git remote get-url origin 2>/dev/null)
