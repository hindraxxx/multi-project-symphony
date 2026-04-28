## Why

Symphony can already orchestrate one Linear-backed workflow per running instance, but operating multiple repositories means juggling multiple localhost dashboards and workflow commands. A local umbrella dashboard gives one place to monitor project-specific Symphony instances while preserving the current isolated per-workflow execution model.

## What Changes

- Add centralized project workflow ownership under the Symphony repository so feature repositories do not need their own `WORKFLOW.md`.
- Add a local project launcher for named Symphony projects, with project-specific workflow paths and dashboard ports.
- Add an umbrella dashboard that runs on one local port and aggregates status from multiple project Symphony instances.
- Add a project selector in the umbrella dashboard so the operator can switch between repositories and see each project's active agents.
- Document the local multi-project operating model, including the distinction between internal per-project ports and the single umbrella dashboard port.

## Capabilities

### New Capabilities
- `umbrella-dashboard`: Local multi-project Symphony operations, including centralized project workflows, named project launch, and aggregate dashboard visibility.

### Modified Capabilities

## Impact

- Affected code: Elixir scripts, workflow examples/templates, dashboard/static UI, documentation, and tests around config/launcher behavior.
- APIs: The existing per-instance `/api/v1/state` endpoint remains the source for project status; the umbrella dashboard consumes those endpoints rather than changing worker orchestration semantics.
- Systems: Local-only development environment. No Vercel/cloud hosting is required for the dashboard to access local workspaces.
