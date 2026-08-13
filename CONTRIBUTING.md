# Contributing

Thank you for helping improve Local Workspace Orchestrator.

## Before you start

- Search existing issues and pull requests.
- Keep each change focused and preserve the read-only coordination boundary.
- Do not include credentials, private workspace data, generated build products, or
  unrelated formatting changes.
- Discuss proposals that add mutation, execution, broader filesystem access, or new
  network destinations before implementing them.

## Validation

Use Swift 6 on macOS 14 or later and run:

```bash
swift test
swift test --sanitize=thread
```

Security-sensitive changes require focused tests proving deterministic, fail-closed
behavior. Do not describe model-generated analysis as authoritative verification.

## Pull requests

Include a concise summary and rationale, tests added or updated, exact validation
commands and results, and any compatibility or security implications.

Concise conventional commit prefixes such as `feat:`, `fix:`, `test:`, `docs:`, and
`chore:` are encouraged.

Do not report vulnerabilities publicly. Follow [SECURITY.md](SECURITY.md).
