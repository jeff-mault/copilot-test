# Copilot Instructions — Mault Governance

This workspace uses Mault to enforce architectural discipline for AI-assisted coding.
When you act as an agent in this repository, use the Mault Language Model Tools:

- `mault_start_<role>` to begin a role (planner, orchestrator, worker, review, tester, compliance).
- `mault_advance_role` to move between roles.
- `mault_check_zone` before writing files to verify you are inside the declared zone.
- `mault_check_budget` before committing to verify file count and LOC stay within the task budget.
- `mault_submit_receipt` at session end to post the MAULT-TASK receipt.

Consult `.mault/plan.md` for sprint context, task zones, budgets, and dependencies.
Refer to the Mault panel in the VS Code sidebar for the current role, mode, and next step.
