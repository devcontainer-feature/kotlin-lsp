#!/bin/bash
set -e

source dev-container-features-test-lib

check "kotlin-lsp on PATH"             bash -c "command -v kotlin-lsp"
check "pinned install dir exists"      bash -c "test -d /usr/local/share/kotlin-lsp"
check "pinned launcher resolves"       bash -c "readlink -f /usr/local/bin/kotlin-lsp | grep -q '/usr/local/share/kotlin-lsp/'"

reportResults
