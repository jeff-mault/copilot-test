<!-- mault-hooks-scaffold-v3 -->
<!--
╔══════════════════════════════════════════════════════════════════════╗
║  MAULT PRO - Multi-Agent Orchestration                               ║
║  Copyright © 2025 Mault. All rights reserved.                        ║
║                                                                      ║
║  This document is licensed for use with the Mault VS Code Extension. ║
║  Redistribution or resale is prohibited.                             ║
║                                                                      ║
║  https://mault.dev | support@mault.dev                               ║
╚══════════════════════════════════════════════════════════════════════╝
-->

# CLAUDE.md — Multi-Agent Governance

@../.mault/mault-rules.md

> Physics, not policy. These rules are enforced by runtime hooks — violations are blocked, not warned.
>
> The import above carries the Mault rulebook — flows, lane, boundaries, and the
> rules no gate can enforce. It is Mault-owned and replaced on upgrade. Anything
> you write in this file is yours and is never overwritten.

---

## Roles & Permissions

| Role | Write Code? | Merge? | Zone/Budget? |
|------|-------------|--------|--------------|
| Planner | No | No | N/A (read-only) |
| Orchestrator | No | No | N/A (creates issues) |
| Worker | Yes | No | Yes (enforced) |
| Review Agent | No | Yes | N/A (reviews only) |
| Tester | No | No | N/A (runs tests) |
| Supervisor | Yes | No | No (escalation) |
| Universal | Yes | Yes | No (unrestricted) |

---

## Git Workflow

- **One branch = one PR = one merge.** Never reuse branches or stack PRs.
- Branch naming: `feat/<issue>-<desc>`, `fix/<issue>-<desc>`
- Workers NEVER push to main or merge PRs
- Review Agent merges when ALL CI passes (`gh pr merge --squash`)
- NEVER use `--no-verify` to bypass pre-commit hooks
- NEVER force push to shared branches
- NEVER amend commits already pushed to remote

---

## Labels (Communication Protocol)

| Label | Meaning | Set By |
|-------|---------|--------|
| `mault-ready` | PR ready for review | Worker |
| `mault-needs-fix` | CI failed, fix required | Review Agent |
| `mault-escalation` | Blocked — human needed | Worker (3 strikes) |
| `mault-zone-active` | Zone claimed by worker | Worker |
| `mault-agent` | Task created by orchestrator | Orchestrator |

---

## Key Conventions

### Three Strikes Rule

If blocked by the same governance check 3 times on the same task:
1. STOP — do not keep retrying
2. Add `mault-escalation` label with strike details
3. Release zone and move to next task

### Receipt Protocol

Workers post a receipt before session ends:
```
MAULT-TASK-<issue>-<sha>-<checks>/<total>-<timestamp>
MAULT-TASK-<issue>-<sha>-<checks>/<total>-<timestamp> | ws-<id>-agent-<n>
```
The second form shows the optional workspace/agent suffix accepted by the receipt gate.

### Zone Enforcement

Workers declare a zone (file paths) per task via `.mault/current-task.json`. Runtime hooks block writes outside the zone. One zone = one owner at a time.

### Budget Enforcement

Each task declares max files and max LOC. PostToolUse hooks block writes that exceed budget.

### Fix-First Protocol

Workers must fix broken PRs (`mault-needs-fix`) before pulling new tasks.

---

## Hook Manifest

Hook counts are not hand-maintained here. Your live inventory is
`.claude/settings.json` -- it is the registry the runtime actually reads, so it
cannot drift from what fires. Read it when you need the authoritative set; this
section describes only what each phase is for.

- **SessionStart** -- resolves your agent's role and loads its state, injects the
  testing rules, and warns when `settings.local.json` has dropped hooks.
- **PreToolUse** -- the deny surface. Blocks writes outside the declared zone or
  the role's permitted paths, blocks source creation without a test, and gates PR
  creation and merges.
- **PostToolUse** -- enforces file-size and SRP limits plus the file-count and LOC
  budget after each write, and detects hard-coded values.
- **Stop** -- the exit gates. Require the task receipt and the role's completion
  artifact, require tests for new source files, and release the zone label.

Hooks are physics. They fire and emit a named rejection identifying both the gate
and the remedy whether or not this file is in context.

## Language Adaptation

Hooks that embed language-specific patterns -- test-file mapping, hard-coded-value
patterns, LOC and function detection, and build/test/lint commands -- need adapting
for non-TypeScript projects. Every other hook reads Git and platform metadata only
and ports unchanged. Run the Mault language-adaptation guide from the command
palette when you port to a new stack.
