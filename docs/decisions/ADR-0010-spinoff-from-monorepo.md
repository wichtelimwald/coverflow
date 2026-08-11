# ADR-0010: Spin-off from the `wichtelimwald/assistance` mono-repo

**Status:** Accepted
**Date:** 2026-05-20
**Supersedes:** N/A
**Related:** ADR-0012 in `wichtelimwald/assistance` (mono-repo split strategy)

## Context

`CoverFlow` was previously one module of the `AssistanceKit` umbrella SwiftPM
package living at `wichtelimwald/assistance:shared-ui/`. The umbrella shipped
seven modules (CoverFlow, GlassOverlay, Markdown, Backgrounds, Buttons,
Compatibility, Styles) under a single product. This had two structural
problems:

1. A change in any one module forced a full umbrella version bump and a
   re-test of all consumers (toogether-app, studienmap-app, earworm-hunt-app,
   etc.), even if those consumers did not use the changed module.
2. Coupling between unrelated modules (e.g. CoverFlow vs. Markdown) was
   architecturally hidden — each module's API surface was indistinguishable
   from the others'.

## Decision

Split the `AssistanceKit` umbrella into four standalone SwiftPM packages,
each in its own GitHub repository:

- `wichtelimwald/coverflow` ← this repo (product `CoverFlow`)
- `wichtelimwald/glass-overlay` (product `GlassOverlay`, depends on `SharedUI`)
- `wichtelimwald/markdown-ui` (product `MarkdownUI`)
- `wichtelimwald/shared-ui` (product `SharedUI`: Backgrounds/Buttons/Compatibility/Styles)

Each repo:

- has its own semver release line
- has zero external dependencies (Apple frameworks only) except where noted
- ships a single library product
- is consumed via remote SwiftPM `upToNextMajorVersion`

## Consequences

**Positive**
- Independent versioning per concern. A CoverFlow patch ships without
  re-testing markdown consumers.
- Public-API contracts are now visible at the package boundary.
- Smaller blast radius for breaking changes.

**Negative**
- Four repos to administer (CI, branch protection, CODEOWNERS).
- Consumers that use multiple modules now need multiple SPM entries plus
  multiple `import` lines.
- One-time migration cost for downstream apps (handled by the
  `migrate-*-app` rewrite scripts in `wichtelimwald/assistance`).

## Implementation notes

- The migration script (`scripts/migrate-coverflow/migrate.sh` in the
  mono-repo) copies `shared-ui/Sources/AssistanceKit/CoverFlow/` and the
  matching `CoverFlowKernelTests.swift` test file, ships a single-target
  `Package.swift`, and tags `v0.1.0`.
- No Git history is preserved from the mono-repo (clean break).
- Mono-repo cleanup (deletion of `shared-ui/Sources/AssistanceKit/CoverFlow/`)
  happens in a separate PR once every consumer of the umbrella package has
  been migrated.
