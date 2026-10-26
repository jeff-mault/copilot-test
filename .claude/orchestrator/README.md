# Multi-Agent Forensics Reference

This file is a diagnostic reference, not a setup guide.

To check that this workspace is set up correctly, run the verifier:

```bash
bash .claude/orchestrator/verify-setup.sh
```

It checks each requirement, names every failure with what to do about it, and
exits non-zero when any check failed. A check it cannot determine reports SKIP
rather than OK.

## Forensics — Diagnostic Files

| File | What It Reveals |
|------|----------------|
| `.claude/hooks-paused.json` | Hooks are parked — user ran Pause command |
| `.claude/settings.paused.json` | Manual escape — user renamed settings.json |
| `.mault/sessions/{id}.json` | Session identity — role, pid, started time |
| `.mault/sessions/{id}/occupancy-checked` | Bootstrap ran but session file may be missing |
| `.mault/sessions/{id}/bootstrap-failure.json` | Bootstrap Phase 5 write failed — error details |
| `.claude/settings.local.json` | Role-specific deny overrides (gitignored) |
| `.claude/hooks/*.js` | Hook source files (untouched by pause/resume) |
