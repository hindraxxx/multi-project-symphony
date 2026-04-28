## Context

Symphony currently runs one workflow per process. Each process reads one `WORKFLOW.md`, polls one configured Linear project, creates isolated per-issue workspaces, and exposes its own local dashboard/API when started with a port. This is a good execution boundary, but it becomes awkward when one operator wants to manage multiple repositories from one place.

The first multi-project step should preserve that execution boundary. The Symphony repository becomes the local "hood" repository that owns project workflow templates and launch ergonomics, while product repositories remain clean and are cloned into per-issue workspaces by project-specific hooks.

## Goals / Non-Goals

**Goals:**
- Support centralized workflow files under the Symphony repository for multiple named projects.
- Provide a local named launcher so an operator can start the correct project workflow without remembering full paths and ports.
- Provide one local umbrella dashboard with a project selector that aggregates status from existing per-project Symphony APIs.
- Preserve the current one-workflow-per-orchestrator execution model.

**Non-Goals:**
- Do not refactor the orchestrator to run multiple workflows inside one process.
- Do not host the dashboard on Vercel or any other cloud service.
- Do not require feature repositories to contain Symphony-specific workflow files.
- Do not change Linear polling, claiming, retry, or workspace execution semantics.

## Decisions

1. Use centralized project workflow directories.
   - Workflow files live under `workflows/<project>/WORKFLOW.md` in the Symphony repository.
   - Each workflow uses absolute local repository paths in `hooks.after_create` so path behavior is clear regardless of current working directory.
   - Alternative considered: keep `WORKFLOW.md` in each feature repo. Rejected because the desired operating model is for Symphony to own orchestration config centrally.

2. Keep one Symphony instance per project behind the umbrella dashboard.
   - Each project still runs its own `symphony-ui` process on a project-specific localhost port.
   - The umbrella dashboard reads each instance's `/api/v1/state` endpoint and merges status for display.
   - Alternative considered: one process supervising multiple workflows. Rejected for the first version because it would require workflow-aware orchestration, process naming, claims, logs, reloads, and dashboard state changes.

3. Add a named launcher before adding full process management.
   - A small launcher maps project names to workflow paths and dashboard ports.
   - It can start one project at a time and print the internal project dashboard URL.
   - Alternative considered: a start-all daemon. Deferred until the basic workflow layout and aggregator experience are validated.

4. Keep the umbrella dashboard local-only.
   - The dashboard runs on a local port and accesses local project APIs.
   - This matches the need to see local workspaces, credentials, Git auth, and Codex execution without exposing machine-local capabilities to a hosted frontend.
   - Alternative considered: hosted dashboard. Rejected for now due to security and local filesystem access constraints.

## Risks / Trade-offs

- Project instance down -> the umbrella dashboard must show the project as unavailable instead of failing the whole page.
- Port conflicts -> the launcher must use stable documented ports and produce a clear error when a port is unavailable.
- Local path drift -> workflow templates should make local repo paths obvious and easy to edit.
- Duplicate process confusion -> the first launcher is intentionally simple; robust start/stop/status process management can be a later change.
- Cross-origin browser restrictions -> prefer serving the umbrella dashboard from a local backend that fetches project API states server-side, or proxy project states through the umbrella process.
