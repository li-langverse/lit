# lit — Li test runner

**lit** runs package tests and enforces **≥ 80%** line coverage (CLI v1). It ships alongside **lip** in the [lip](https://github.com/li-langverse/lip) repository layout; this repo tracks the **lit** subtree and CI.

## Status

Bootstrap and agent-kit are in place; see [lip](https://github.com/li-langverse/lip) for the combined lip+lit workflow.

## Quick start

```bash
# Build lic (sibling checkout)
cd ../li && ./scripts/build.sh

# Run lit CI in this repo
cd ../lit && ./scripts/ci.sh
```

## Docs

| Doc | Content |
|-----|---------|
| [docs/handbook.md](docs/handbook.md) | Cross-links to master plan and standards |
| [lip: lit.md](https://github.com/li-langverse/lip/blob/main/docs/lit.md) | User-facing lit reference |

## Agents

[AGENTS.md](AGENTS.md) · [roadmap engineering standards](https://github.com/li-langverse/roadmap/blob/main/docs/ecosystem/engineering-standards.md)
