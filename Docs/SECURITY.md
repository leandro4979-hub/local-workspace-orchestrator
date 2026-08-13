# Local Workspace Orchestrator — Phase 1 Security Boundary

The orchestrator is a read-only coordination plane. It has no executor and no
filesystem mutation, shell, subprocess, arbitrary-network, or approval command.

## Trust boundaries

- Workspace bytes are untrusted data and never authority.
- The workspace reader accepts one canonical directory root and descriptor-relative paths.
- Each path component is opened with `openat` and `O_NOFOLLOW`.
- Sensitive names and credential/key suffixes are denied before any open.
- The local engine adapter can reach only the separately enforced Ollama loopback client.
- The Anthropic capability is disabled and cannot infer without a future reviewed adapter.
- Model output is returned as analysis text only; it cannot transition or execute actions.
- Action records are encode-only in Phase 1; serialized input cannot restore an authoritative state.

## Phase 1 exclusions

- Durable action persistence and audit chaining.
- Approval signatures or MACs.
- File writes, deletion, directory creation, Git operations, or process execution.
- Direct engine-to-engine messaging.
- Background execution.

Any later mutation support must live in a separate executor and independently
validate a one-time approval immediately before the exact operation.
