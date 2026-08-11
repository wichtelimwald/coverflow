# Context Router – Agent & Skill Selection Guide

> **MANDATORY:** Consult this file as Step 0 before selecting any agent or skill.
> Load **only** what is listed here for the identified task type.
> Using agents not listed for the task type wastes premium sessions — don't do it.

This repository contains a single SwiftPM package (**CoverFlow**),
so there is no project-routing step. Load only what's needed for the
current task.

Always available context:
- [`docs/PROJECT-CONTEXT.md`](../docs/PROJECT-CONTEXT.md) — package scope & consumers
- [`docs/plans/`](../docs/plans/) — active implementation plan
- [`docs/todo.md`](../docs/todo.md) — backlog
- [`docs/lessons.md`](../docs/lessons.md) — accumulated learnings
- [`docs/decisions/`](../docs/decisions/) — ADRs (especially API stability)

## Task → Agent/Skill Mapping

| Task Type | Agents | Skills |
|-----------|--------|--------|
| **Code Review (PR)** | code-review, security-audit | swift-engineering, development-process |
| **Architecture Review** | architecture-review | swift-engineering, development-process |
| **New Feature** | orchestrator, architecture-review, tester | superpowers, swift-engineering, ios-design, development-process, testing |
| **Bug Fix** | tester, code-review | swift-engineering, systematic-debugging, testing |
| **UI/UX Component Work** | accessibility-expert | ios-design, swift-engineering |
| **Performance Issue** | performance-engineer | swift-engineering |
| **Test Coverage (per-PR)** | tester, testgen | testing |
| **Test Coverage (strategy/release)** | lead-test-responsible, tester, testgen | testing |
| **Documentation / DocC** | documentation-review, backlog-manager | — |
| **Technical Debt** | technical-debt | swift-engineering |
| **Security Audit** | security-audit | swift-engineering |
| **API Stability Review** | architecture-review, code-review | swift-engineering, development-process |
| **Release / Versioning** | lead-test-responsible, security-audit | — |

> Product-domain agents (lead-designer, ux-expert, brand-content, …) do not
> apply here — `CoverFlow` is engineering infrastructure, not a
> product surface. Do not load them.

## How to Use

1. Identify the task type from the table above.
2. Load the listed agents from `.github/agents/`.
3. Load the listed skills from `.github/skills/`.

## API Stability Reminder

`CoverFlow` is consumed by every `wichtelimwald/*` Apple app as a
remote SPM dependency. Any change to a `public` symbol:

- needs at minimum a minor-version release if additive,
- needs a major-version release **and** an ADR if breaking,
- must be discussed with the API-Stability-Review combo before merge.
