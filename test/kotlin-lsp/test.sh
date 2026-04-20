#!/bin/bash
#
# Auto-generated test for the 'kotlin-lsp' feature with default options.
# See https://github.com/devcontainers/cli/blob/main/docs/features/test.md

set -e

source dev-container-features-test-lib

check "kotlin-lsp on PATH"            bash -c "command -v kotlin-lsp"
check "kotlin-lsp launcher executable" bash -c "test -x \"$(command -v kotlin-lsp)\""
check "kotlin-lsp install dir exists"  bash -c "test -d /usr/local/share/kotlin-lsp"
check "kotlin-lsp.sh present"          bash -c "find /usr/local/share/kotlin-lsp -maxdepth 4 -type f -name 'kotlin-lsp.sh' | grep -q ."
check "java >= 17 available"           bash -c 'v=$(java -version 2>&1 | head -n1 | awk -F\" "{print \$2}" | awk -F. "{print (\$1==1)?\$2:\$1}"); [ "${v:-0}" -ge 17 ]'

reportResults
