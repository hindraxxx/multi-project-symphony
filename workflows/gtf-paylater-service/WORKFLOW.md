---
tracker:
  kind: linear
  project_slug: "gtf-paylater-project-a2a1a7c3ba8d"
  active_states:
    - Todo
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
agent:
  max_concurrent_agents: 10
  max_turns: 20
codex:
  command: codex --config shell_environment_policy.inherit=all --config 'model="gpt-5.5"' --config model_reasoning_effort=xhigh app-server
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
