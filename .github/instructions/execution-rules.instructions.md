---
description: "Mandatory execution rules for every Copilot session in the coverflow (CoverFlow) repository."
applyTo: "**/*"
---

# Copilot Execution Rules

These rules apply to **every** Copilot session in this repository.

---

## 0. Context Router — Mandatory First Step

Before selecting agents or skills, consult `.github/context-router.md`.
Identify the task type from its table and load **only** the listed agents and skills for that type.
Do not load agents not listed for the current task type.

---

## 1. Branch-Based Workflow

All work on branches. Never commit to `main`. If on `main`, create a branch first.

---

## 2. Architecture & Decisions

Before modifying code, check `docs/decisions/` for ADRs.
New architectural choices require a new ADR (`docs/decisions/template.md`).

---

## 3. Lessons Learned

Before starting: read `docs/lessons.md`. After non-trivial sessions: append new lessons.
Format: `### Topic (YYYY-MM-DD)` followed by numbered findings.

---

## 4. Session Summary

Every session ends with a summary **in the chat response** (not only in the PR description):
- **Agents Used** table — every agent considered, with ✅/⏭️/❌ status and one-line result
- Decisions made (ADRs created/updated)
- Lessons learned
- Recommendations for next session

See `.github/agents/self-management.md` for the required output template.

---

## 5. Backlog Discipline

Check `docs/todo.md` before starting. Create entries for discovered work.
Update status of items you worked on. Reference backlog items in PRs.

---

## 6. Concept-Before-Code

Non-trivial features (effort ≥ M): check for a concept in `docs/concepts/` or create one
using `docs/concepts/template.md`. Move fully implemented concepts to `docs/concepts/implemented/`.

---

## 7. Implementation Planning

Check `docs/plans/plan-*.md` for an active plan (🟢).
If a plan exists → implement next open step (⬜). If complete → archive to `docs/plans/implemented/`.
If no plan → scan backlog, create a new 3–8 step plan.
See `.github/instructions/implementation-planning.instructions.md` for full workflow.

---

## 8. parallel_validation — Code Changes Only

Run `parallel_validation` **only when** Swift source files were changed AND the changes are not purely documentary.

**Skip `parallel_validation` for:** plan updates, ADRs, backlog entries, README edits, `.md`-only PRs.

---

## 9. API Stability — Mandatory User Approval for Breaking Changes

`CoverFlow` is consumed as a remote SPM dependency by every
`wichtelimwald/*` Apple app. Every `public` symbol is a contract.

No agent may unilaterally:
- remove, rename, or change the signature of a `public` symbol,
- change semantics of an existing `public` API,
- remove an existing module from the public surface,
- introduce a new external dependency.

**Process:** Stop → describe change → explain blast radius (which consumer
apps break) → propose alternatives (e.g. add new API alongside, deprecate
old) → wait for explicit approval → document in ADR → bump major version.

When in doubt, ask. Your risk assessment may be wrong.

---

## 10. Versioning & Releases

- Patch releases: bug fixes, no API surface change.
- Minor releases: additive API surface only; existing call sites keep working.
- Major releases: any breaking change. Requires ADR + user approval (rule 9).

Tag on `main` after a green build: `git tag -a v<x.y.z> -m "..."` then push the tag.
Consumers pin `upToNextMajorVersion`, so minor/patch ship automatically.
