# Security Policy

## Supported versions

Security fixes are provided for the latest version on the `main` branch.

## Reporting a vulnerability

Please report vulnerabilities privately through GitHub Security Advisories rather
than opening a public issue. Include the affected version or commit, minimal
reproduction steps, impact, and a suggested mitigation when available. Do not
include real credentials, private workspace content, or exploit payloads containing
sensitive user data. Allow reasonable time for investigation before disclosure.

## Supported boundary

Phase 1 is read-only. The project has no executor. Workspace content and model output
are untrusted data, and serialized data cannot restore an authoritative action state.

Reports involving path traversal, symlink/TOCTOU behavior, descriptor lifetime,
state-transition bypass, response-bound bypass, or unexpected external network access
are particularly valuable.

## Project boundary

The orchestrator must not silently upload workspace content, execute model output,
or broaden filesystem access beyond the explicitly selected workspace. Changes to
these boundaries require explicit security review and corresponding tests.

## Contributor expectations

- Never commit credentials, tokens, private keys, personal data, or `.env` files.
- Preserve least-privilege filesystem, process, and network access.
- Treat workspace content, prompts, and model output as untrusted data.
- Review dependency and CI action updates before merging them.
