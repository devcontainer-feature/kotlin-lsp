
# Kotlin LSP (kotlin-lsp)

Installs the JetBrains Kotlin Language Server (kotlin-lsp) and registers it as a CLI command on the PATH.

## Example Usage

```json
"features": {
    "ghcr.io/devcontainer-feature/kotlin-lsp/kotlin-lsp:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Version of kotlin-lsp to install (e.g. '262.2310.0'), or 'latest' to fetch the most recent release. | string | latest |
| installJava | Install OpenJDK 17 (headless JRE) when no Java >= 17 is detected on PATH. | boolean | true |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainer-feature/kotlin-lsp/blob/main/src/kotlin-lsp/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
