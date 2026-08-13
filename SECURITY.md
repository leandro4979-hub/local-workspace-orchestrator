# Security Policy

Please report vulnerabilities privately through GitHub Security Advisories. Do not
include real credentials, private workspace content, or exploit payloads containing
sensitive user data in a public issue.

## Supported boundary

Phase 1 is read-only. The project has no executor. Workspace content and model output
are untrusted data, and serialized data cannot restore an authoritative action state.

Reports involving path traversal, symlink/TOCTOU behavior, descriptor lifetime,
state-transition bypass, response-bound bypass, or unexpected external network access
are particularly valuable.
