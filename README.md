# kotlin-lsp dev container feature

A [dev container Feature](https://containers.dev/implementors/features/) that
installs the [JetBrains Kotlin Language Server](https://github.com/Kotlin/kotlin-lsp)
into your dev container and registers it as the `kotlin-lsp` command on `PATH`.

## Usage

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/devcontainer-feature/kotlin-lsp/kotlin-lsp:1": {}
    }
}
```

```bash
$ command -v kotlin-lsp
/usr/local/bin/kotlin-lsp

$ kotlin-lsp --help
```

## Options

| Option        | Type    | Default  | Description                                                                                         |
|---------------|---------|----------|-----------------------------------------------------------------------------------------------------|
| `version`     | string  | `latest` | kotlin-lsp release to install (e.g. `262.2310.0`), or `latest` to fetch the most recent release.    |
| `installJava` | boolean | `true`   | Install an OpenJDK JRE (21 → 17 → distro default) when no Java ≥ 17 is detected on `PATH`.          |

### Pinning a version

```jsonc
{
    "features": {
        "ghcr.io/devcontainer-feature/kotlin-lsp/kotlin-lsp:1": {
            "version": "262.2310.0"
        }
    }
}
```

### Bringing your own Java

If your base image (or another feature such as
`ghcr.io/devcontainers/features/java`) already provides Java ≥ 17, set
`installJava` to `false` to skip the JRE install:

```jsonc
{
    "features": {
        "ghcr.io/devcontainers/features/java:1": { "version": "21" },
        "ghcr.io/devcontainer-feature/kotlin-lsp/kotlin-lsp:1": {
            "installJava": false
        }
    }
}
```

## What the feature does

1. Ensures `curl`, `unzip`, and `ca-certificates` are installed.
2. Installs a headless JRE (≥ 17) if one is not already present and
   `installJava` is true.
3. Resolves the target version (calls the GitHub Releases API when
   `version=latest`).
4. Downloads the architecture-specific standalone archive from
   `download-cdn.jetbrains.com` and verifies the SHA-256 checksum when
   available.
5. Extracts into `/usr/local/share/kotlin-lsp` and symlinks the launcher
   script to `/usr/local/bin/kotlin-lsp`.

### Supported platforms

- `linux-x64`
- `linux-aarch64`

## Testing

```bash
npm install -g @devcontainers/cli
devcontainer features test -f kotlin-lsp .
```

## License

See [LICENSE](./LICENSE).
