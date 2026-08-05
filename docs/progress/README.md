# docs/progress/ — File-Based Task State

This directory is the working memory of the ACE loop (Harness Engineering
Standard, `.ace/standards/harness-engineering.md` §2). Agents read state from
here instead of relying on conversation history, which is what makes context
flushing between sessions safe.

## Files

| File | Written by | Purpose |
| ---- | ---------- | ------- |
| `tasks.json` | Architect (created), orchestrator (updated) | The task queue and state machine. Single source of truth for work state. |
| `task_<ID>_result.md` | Generator | Progress log written when a task completes — the memory handed to the next agent. |
| `task_<ID>_attempt<N>_trace.md` | Orchestrator/runner | Full execution + verify trace for a failed attempt; input to the Reflector. |
| `tasks.example.json` | Framework | Reference queue demonstrating the format, including a blocked (stalled) task. |

## tasks.json

- **Schema (source of truth):** `.ace/schemas/tasks.schema.json` (JSON Schema draft 2020-12)
- **Validator:** `npx -y -p create-ace-framework@2.7.0 ace-framework loop --dry-run` — reports queue state and any schema/invariant violation without changing anything. (The upstream README points at `node cli/lib/validate-tasks.js`; that path only exists in the framework's own repo. In a scaffolded project the zero-dependency validator ships inside the npm package and the loop runs it on every invocation.)

### Task states

`pending → in_progress → verified` is the happy path. A failed verify gate
moves the task to `failed` (retry budget remaining) or `blocked` (budget
exhausted, or stall detected). `skipped` marks tasks descoped by the Architect.

### Loop invariants

1. At most one task is `in_progress` at any time.
2. A task is eligible only when every id in `depends_on` is `verified`; no
   self- or cyclic dependencies.
3. `attempts` never exceeds `max_attempts` (task-level, else
   `defaults.max_attempts`). When the budget is exhausted — or the same
   failure `fingerprint` occurs twice consecutively — the orchestrator
   transitions the task to `blocked` with a human-actionable
   `blocked_reason` and halts.

## Telemetry

Loop telemetry lands in `.ace/feedback/loop-metrics.jsonl` — one JSON object
per line, append-only, **metadata only** (never prompts, code, or trace
contents). View the summary with `ace-framework loop --report`.

Events and their fields (all events carry `ts` ISO timestamp):

| event | fields |
| ----- | ------ |
| `attempt_start` | `task`, `attempt`, `runner` |
| `attempt_verified` | `task`, `attempt`, `duration_ms` |
| `attempt_failed` | `task`, `attempt`, `fingerprint`, `decision` (retry\|block), `duration_ms` |
| `task_blocked` | `task`, `attempt`, `fingerprint` |
| `runner_error` | `task`, `attempt`, `detail` (error message head) |
| `loop_complete` | — |

The report computes tasks touched, total attempts, first-pass rate, average
attempts per verified task, blocked count, and repeat failure fingerprints
(the same fingerprint failing more than once marks a playbook-rule
candidate). A rising first-pass rate over time is the evidence that the
self-improving harness is actually improving.
