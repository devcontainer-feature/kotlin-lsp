#!/usr/bin/env bash
set -euo pipefail

echo "Activating feature 'kotlin-lsp'"

VERSION="${VERSION:-latest}"
INSTALLJAVA="${INSTALLJAVA:-true}"

INSTALL_DIR="/usr/local/share/kotlin-lsp"
BIN_LINK="/usr/local/bin/kotlin-lsp"
CDN_BASE="https://download-cdn.jetbrains.com/kotlin-lsp"
RELEASES_API="https://api.github.com/repos/Kotlin/kotlin-lsp/releases/latest"

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This feature must be installed as root." >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

apt_install() {
    export DEBIAN_FRONTEND=noninteractive
    if ! apt-get update -y; then
        echo "ERROR: apt-get update failed" >&2
        return 1
    fi
    apt-get install -y --no-install-recommends "$@"
}

ensure_pkg() {
    local cmd="$1"
    local pkg="$2"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Installing missing dependency: $pkg (provides $cmd)"
        apt_install "$pkg"
    fi
}

# ---------------------------------------------------------------------------
# Base dependencies
# ---------------------------------------------------------------------------

ensure_pkg curl curl
ensure_pkg unzip unzip
ensure_pkg ca-certificates ca-certificates

# ---------------------------------------------------------------------------
# Java check / install
# ---------------------------------------------------------------------------

java_major_version() {
    if ! command -v java >/dev/null 2>&1; then
        echo "0"
        return
    fi
    local raw
    raw="$(java -version 2>&1 | head -n 1 | awk -F\" '{print $2}')"
    case "$raw" in
        1.*) echo "${raw#1.}" | awk -F. '{print $1}' ;;
        "")  echo "0" ;;
        *)   echo "$raw" | awk -F. '{print $1}' ;;
    esac
}

install_java() {
    # Prefer the highest available LTS >= 17. Different Debian/Ubuntu releases
    # ship different candidates: bookworm has openjdk-17, trixie/noble have
    # openjdk-21, etc. default-jre-headless is the universal fallback.
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    local pkg
    for pkg in openjdk-21-jre-headless openjdk-17-jre-headless default-jre-headless; do
        echo "Attempting to install Java package: $pkg"
        if apt-get install -y --no-install-recommends "$pkg"; then
            echo "Installed Java package: $pkg"
            return 0
        fi
    done
    echo "ERROR: failed to install any of the candidate Java packages" >&2
    return 1
}

CURRENT_JAVA="$(java_major_version)"
if [ "${CURRENT_JAVA:-0}" -lt 17 ]; then
    if [ "${INSTALLJAVA,,}" = "true" ]; then
        echo "Java >= 17 not found (detected: ${CURRENT_JAVA:-none}); installing JRE"
        install_java
        CURRENT_JAVA="$(java_major_version)"
        if [ "${CURRENT_JAVA:-0}" -lt 17 ]; then
            echo "ERROR: installed JRE reports version ${CURRENT_JAVA}; kotlin-lsp requires >= 17" >&2
            exit 1
        fi
        echo "Detected Java major version after install: ${CURRENT_JAVA}"
    else
        echo "WARNING: Java >= 17 was not found and installJava=false. kotlin-lsp will not run until a JRE is provided." >&2
    fi
else
    echo "Detected Java major version: ${CURRENT_JAVA}"
fi

# ---------------------------------------------------------------------------
# Resolve target version
# ---------------------------------------------------------------------------

resolve_latest_version() {
    local tag
    tag="$(curl -fsSL "$RELEASES_API" \
        | grep -m1 '"tag_name"' \
        | sed -E 's/.*"tag_name"\s*:\s*"([^"]+)".*/\1/')"
    if [ -z "$tag" ]; then
        echo "ERROR: failed to determine latest kotlin-lsp version from GitHub API" >&2
        return 1
    fi
    # Tag looks like "kotlin-lsp/v262.2310.0" -> "262.2310.0"
    echo "${tag##*/v}"
}

if [ "$VERSION" = "latest" ] || [ -z "$VERSION" ]; then
    VERSION="$(resolve_latest_version)"
fi

echo "Installing kotlin-lsp version: ${VERSION}"

# ---------------------------------------------------------------------------
# Resolve platform
# ---------------------------------------------------------------------------

ARCH="$(uname -m)"
case "$ARCH" in
    x86_64|amd64)   PLATFORM="linux-x64" ;;
    aarch64|arm64)  PLATFORM="linux-aarch64" ;;
    *) echo "ERROR: unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

ARCHIVE="kotlin-lsp-${VERSION}-${PLATFORM}.zip"
URL="${CDN_BASE}/${VERSION}/${ARCHIVE}"

# ---------------------------------------------------------------------------
# Download and verify
# ---------------------------------------------------------------------------

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Downloading: $URL"
curl -fsSL "$URL"        -o "${TMP_DIR}/${ARCHIVE}"
curl -fsSL "${URL}.sha256" -o "${TMP_DIR}/${ARCHIVE}.sha256" || true

if [ -s "${TMP_DIR}/${ARCHIVE}.sha256" ]; then
    EXPECTED_SHA="$(awk '{print $1}' "${TMP_DIR}/${ARCHIVE}.sha256")"
    ACTUAL_SHA="$(sha256sum "${TMP_DIR}/${ARCHIVE}" | awk '{print $1}')"
    if [ "$EXPECTED_SHA" != "$ACTUAL_SHA" ]; then
        echo "ERROR: SHA-256 mismatch for $ARCHIVE" >&2
        echo "  expected: $EXPECTED_SHA" >&2
        echo "  actual:   $ACTUAL_SHA"   >&2
        exit 1
    fi
    echo "SHA-256 checksum verified."
else
    echo "WARNING: SHA-256 checksum file not available; skipping verification." >&2
fi

# ---------------------------------------------------------------------------
# Extract
# ---------------------------------------------------------------------------

rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
unzip -q "${TMP_DIR}/${ARCHIVE}" -d "$INSTALL_DIR"

# The distributed zip sometimes drops the executable bit on the bundled JRE
# binaries (java, javac, ...), and the upstream launcher tries to chmod +x
# them at runtime — which fails when the container runs as a non-root
# remoteUser because the install dir is root-owned. Fix the permissions
# once, here, while we still have root.
chmod -R a+rX "$INSTALL_DIR"
find "$INSTALL_DIR" -type f -name '*.sh' -exec chmod a+x {} +
while IFS= read -r -d '' bin_dir; do
    find "$bin_dir" -maxdepth 1 -type f -exec chmod a+x {} +
done < <(find "$INSTALL_DIR" -type d -name bin -print0)

# Locate the launcher script. Different releases nest content differently,
# so search rather than hard-code a path.
LAUNCHER="$(find "$INSTALL_DIR" -maxdepth 4 -type f -name 'kotlin-lsp.sh' | head -n 1)"
if [ -z "$LAUNCHER" ]; then
    echo "ERROR: kotlin-lsp.sh not found inside extracted archive at $INSTALL_DIR" >&2
    exit 1
fi
chmod a+x "$LAUNCHER"

# ---------------------------------------------------------------------------
# Register CLI command
# ---------------------------------------------------------------------------

ln -sf "$LAUNCHER" "$BIN_LINK"
chmod +x "$BIN_LINK"

echo "kotlin-lsp installed:"
echo "  launcher : $LAUNCHER"
echo "  command  : $BIN_LINK"
echo "Done."
