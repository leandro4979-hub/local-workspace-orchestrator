# Local Workspace Orchestrator

[![CI](https://github.com/leandro4979-hub/local-workspace-orchestrator/actions/workflows/ci.yml/badge.svg)](https://github.com/leandro4979-hub/local-workspace-orchestrator/actions/workflows/ci.yml)
[![Swift](https://img.shields.io/badge/Swift-6-orange.svg)](https://www.swift.org/)
[![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-blue.svg)](https://www.apple.com/macos/)
[![License](https://img.shields.io/github/license/leandro4979-hub/local-workspace-orchestrator.svg)](LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/leandro4979-hub/local-workspace-orchestrator.svg)](https://github.com/leandro4979-hub/local-workspace-orchestrator/commits/main)

A security-first, read-only coordination plane for local AI-assisted source analysis
on macOS. It can inspect one explicitly selected workspace and ask a fixed local
Gemma model for advisory analysis without granting the model filesystem mutation,
shell, process-launch, approval, or execution authority.

## Why this exists

Most “agent” demos collapse context, model output, approval, and execution into one
privileged loop. This project keeps them separate. Phase 1 deliberately stops at
read-only analysis.

## Enforced boundaries

- Descriptor-relative traversal using `openat` and `O_NOFOLLOW`.
- Literal relative paths only; absolute paths, traversal, symlinks, `.git`, `.env`,
  credentials, keys, build artifacts, oversized files, and binary content fail closed.
- Versioned, encode-only action records with actor-authorized state transitions.
- Local inference through the pinned
  [ollama-local-client](https://github.com/leandro4979-hub/ollama-local-client).
- Fixed `127.0.0.1:11434` and `gemma3:4b` engine boundary.
- Anthropic capability is present only as disabled metadata in Phase 1.
- Model responses are advisory text and cannot approve or execute actions.

## Requirements

- macOS 14 or later
- Swift 6
- Ollama bound to `127.0.0.1:11434`
- `gemma3:4b` installed locally

## Build and test

```bash
swift test
swift test --sanitize=thread
swift build -c release --product workspace-orchestrator
```

The test suite covers state-transition authorization, approval skipping, terminal
states, traversal, symlink leaves and directories, secret-path denial, byte and
encoding limits, prompt injection as data, and 500 concurrent reads through one
shared `WorkspaceReader` under Thread Sanitizer.

## Usage

```bash
swift run workspace-orchestrator status

printf '%s\n' 'Review this file for security issues.' |
  swift run workspace-orchestrator analyze \
    /path/to/workspace \
    Sources/Example.swift
```

The instruction is accepted through standard input to avoid shell-history exposure.

## Non-goals

Phase 1 has no executor, file write, deletion, Git operation, shell command,
subprocess, background task loop, browser integration, or model-to-model authority.

See [Docs/SECURITY.md](Docs/SECURITY.md) for the detailed boundary and
[SECURITY.md](SECURITY.md) for vulnerability reporting.

## Contributing

Contributions are welcome when they preserve the documented security model. Read
[CONTRIBUTING.md](CONTRIBUTING.md) before opening an issue or pull request.

## License

MIT
