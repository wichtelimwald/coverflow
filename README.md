# coverflow

A horizontal card-carousel SwiftUI component with focus zoom and tilt,
extracted from `wichtelimwald/assistance` (previously part of the
`AssistanceKit` umbrella in `shared-ui/`).

> Spun off in 2026. See
> [`docs/decisions/ADR-0010-spinoff-from-monorepo.md`](docs/decisions/ADR-0010-spinoff-from-monorepo.md).

---

## Requirements

- Swift 5.9+
- macOS 14+ · iOS 17+
- Xcode 15+
- Zero external dependencies (Apple frameworks only)

## Usage

Add as a remote SwiftPM dependency:

```swift
.package(
    url: "https://github.com/wichtelimwald/coverflow.git",
    .upToNextMajor(from: "0.1.0")
)
```

…and depend on the `CoverFlow` product from your target:

```swift
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "CoverFlow", package: "coverflow"),
    ]
)
```

Then:

```swift
import CoverFlow
```

## Build & Test

```bash
swift build
swift test
```

## Versioning

Semver. Consumers pin `upToNextMajorVersion`. See
[`.github/copilot-instructions.md`](.github/copilot-instructions.md) for the
API-stability rules that apply to every change here.

## Sibling packages

This package is one of four spun off from the `AssistanceKit` umbrella:

| Package         | Repo                                                   |
|-----------------|--------------------------------------------------------|
| `CoverFlow`     | https://github.com/wichtelimwald/coverflow             |
| `GlassOverlay`  | https://github.com/wichtelimwald/glass-overlay         |
| `MarkdownUI`    | https://github.com/wichtelimwald/markdown-ui           |
| `SharedUI`      | https://github.com/wichtelimwald/shared-ui (Backgrounds/Buttons/Compatibility/Styles) |
