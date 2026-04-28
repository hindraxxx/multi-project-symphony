---
tracker:
  kind: linear
  project_slug: "gtf-paylater-project-a2a1a7c3ba8d"
  active_states:
    - OpenSpec Explore
    - OpenSpec Propose
    - In Progress
    - Merging
    - Rework
  terminal_states:
    - Closed
    - Cancelled
    - Canceled
    - Duplicate
    - Done
polling:
  interval_ms: 5000
workspace:
  root: ~/code/symphony-workspaces/gtf-paylater-service
hooks:
  after_create: |
    git clone /Users/liem.sanjaya/gtf/gpl/gtf-paylater-service .
    mkdir -p .codex/skills
    cp -R /Users/liem.sanjaya/gtf/gpl/symphony/.codex/skills/openspec-* .codex/skills/ 2>/dev/null || true
agent:
  max_concurrent_agents: 10
  max_turns: 20
codex:
  command: codex --skip-git-repo-check --config shell_environment_policy.inherit=all --config 'model="gpt-5.5"' --config model_reasoning_effort=low app-server
  read_timeout_ms: 60000
  approval_policy: never
  thread_sandbox: workspace-write
  turn_sandbox_policy:
    type: workspaceWrite
---

You are working on a Linear ticket for the `gtf-paylater-service` repository.

Issue context:
Identifier: {{ issue.identifier }}
Title: {{ issue.title }}
Current status: {{ issue.state }}
Labels: {{ issue.labels }}
URL: {{ issue.url }}

Description:
{% if issue.description %}
{{ issue.description }}
{% else %}
No description provided.
{% endif %}

Work only in the provided repository copy. Do not touch any other path.

Follow the repository instructions, keep progress recorded in Linear, and move the issue through the configured workflow only when the matching quality bar is met.

## Status routing

- `Todo` is a staging state and is not auto-started by this workflow.
- `OpenSpec Explore` means discovery only: read context, capture findings/questions in the Linear workpad, do not implement, do not create a PR, and do not move the issue automatically.
- `OpenSpec Propose` means OpenSpec artifact generation only: create or complete proposal/design/spec/tasks, validate the OpenSpec change when complete, do not implement, do not create a PR, and do not move the issue automatically.
- `In Progress` means implementation. If the issue explicitly references an existing OpenSpec change, run OpenSpec apply for that change; otherwise implement directly.
- `Human Review` means wait for human review and do not code.
- `Merging` means land/merge according to repository workflow.
- `Rework` means address review feedback and return to `Human Review` only after validation passes.

Do not infer that a ticket needs OpenSpec Explore or OpenSpec Propose based on size, ambiguity, labels, or wording. The human selects those routes by moving the Linear issue into the matching state.

## OpenSpec Explore flow

When `Current status` is `OpenSpec Explore`:

1. Do not implement code, create commits, push branches, or open PRs.
2. Find or create the single `## Codex Workpad` Linear comment.
3. Read the issue description, comments, existing repository docs/code that clarify the question, and any existing OpenSpec files if present.
4. Update the workpad with concise exploration output:
   - `### Problem Understanding`
   - `### Findings`
   - `### Options`
   - `### Risks`
   - `### Open Questions`
   - `### Recommended Next State`
5. Resolve questions from repository/issue evidence when possible. If a question requires human product/design judgment, leave it under `Open Questions` with a clear requested answer.
6. Leave the Linear issue in `OpenSpec Explore`. The human will manually move it to `OpenSpec Propose` or `In Progress`.
7. Final response should only summarize what was captured and any blockers.

## OpenSpec Propose flow

When `Current status` is `OpenSpec Propose`:

1. Do not implement code, create commits, push branches, or open PRs.
2. Use the repo-local `openspec` CLI if available to create or continue a change. If the CLI or config is unavailable, record the blocker in the workpad instead of implementing.
3. Prefer an explicit change name from issue text such as `OpenSpec change: <name>`; otherwise derive a kebab-case name from the title.
4. Create or complete proposal, design, specs, and tasks until the change is apply-ready.
5. Validate with `openspec validate <change-name> --strict` when possible.
6. Update the workpad with artifact paths, validation result, and any open questions.
7. Leave the Linear issue in `OpenSpec Propose`. The human will manually move it to `In Progress`.
