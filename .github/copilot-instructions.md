# GitHub Copilot – Instructions (coverflow / CoverFlow)

Swift Package · macOS 14+ · iOS 17+ · Swift 5.9+.
This repository contains exactly **one** SwiftPM package: **CoverFlow**.
Domain context lives in [`docs/PROJECT-CONTEXT.md`](../docs/PROJECT-CONTEXT.md).

---

## Scope

`CoverFlow` is a focused, reusable Swift package consumed by the
`wichtelimwald/*` Apple apps as a **remote SwiftPM dependency** pinned
`upToNextMajorVersion` from a tagged release. Breaking changes require a
major-version bump and an ADR in [`docs/decisions/`](../docs/decisions/).

This package was spun off from the `wichtelimwald/assistance` mono-repo in
2026 (see [`docs/decisions/ADR-0010-spinoff-from-monorepo.md`](../docs/decisions/ADR-0010-spinoff-from-monorepo.md)).

---

## Architecture & Principles

Clean Architecture · SOLID · KISS / DRY · Protocol-Oriented Design.
Modern Swift: `async/await`, `Actor`, no `DispatchQueue` in new code.
Security by Default · Test-Driven · DocC for all public APIs.
**API stability comes first** — every public symbol is a contract.

---

## Hard Gates

- No code before design — non-trivial features need a spec.
- No fixes without root cause.
- No completion without verification evidence (`swift test` green).
- No production code without tests (TDD).
- No public-API breakage without a major version bump + ADR.
- No external dependencies without an ADR.
- Never commit to `main` — all work on branches.

---

## Code Style

| Rule | Value |
|------|-------|
| Language | English (code, comments, docs) |
| Naming | [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) |
| Formatting | 4-space indent, 120 char max |
| Access control | `public` only when intentional; `internal` by default |
| Error handling | Typed errors (`throws` + concrete `Error` types) |
| Optionals | No `!`, no `try!` — use `guard`, `if let`, `??` |
| Observation | `@Observable` only — never `@ObservedObject`/`ObservableObject` |
| Concurrency | `@MainActor` for UI, `actor` for shared state |
| Memory | `[weak self]` in all escaping closures |
| DocC | Every `public` symbol gets a doc comment with a brief + parameters |

---

## Build & Test

```bash
swift build
swift test
```

CI runs `swift build` + `swift test` on macOS and Linux.

---

## Release Workflow

1. Land changes on `main` via PR (build & test green).
2. Decide on the next semver:
   - Patch: bug fix, no API change
   - Minor: additive API change, fully backward-compatible
   - Major: any breaking API change (must have ADR)
3. Tag: `git tag -a v<x.y.z> -m "..."` and push the tag.
4. (Optional) Create a GitHub Release from the tag.

Consumers pin `upToNextMajorVersion` from the version they adopt, so minor
and patch releases ship automatically; major bumps are opt-in per consumer.

---

## Session Workflow

1. Branch check — not on `main`? Create a working branch.
2. Check `docs/plans/` for an active plan → implement next open step.
3. No plan? Scan `docs/todo.md` → create a 3–8 step plan.
4. During: ADR for decisions in `docs/decisions/`, lessons to `docs/lessons.md`, new items to `docs/todo.md`.
5. Close-out: Session Summary in PR description (see `.github/agents/self-management.md`).

Slash commands: see [`.github/prompts/slash-commands.md`](prompts/slash-commands.md).
