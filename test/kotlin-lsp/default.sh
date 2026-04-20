#!/bin/bash
set -e

source dev-container-features-test-lib

check "kotlin-lsp on PATH"   bash -c "command -v kotlin-lsp"
check "kotlin-lsp executable" bash -c "test -x \"$(command -v kotlin-lsp)\""

reportResults
