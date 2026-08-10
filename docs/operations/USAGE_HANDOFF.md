# Usage Handoff Procedure

## Stop threshold

- When visible Codex usage is 3% or lower, stop assigning new work.

## Required handoff

- Ask each active branch to report completed, committed, completed but uncommitted, in progress, blockers, and next steps through OPLOG_HANDOFF.
- Oplog consolidates the dated summary into the single log, commits, and pushes.
- PM stops the watchdog after handoff completion. Work resumes only after the user explicitly restarts it.
