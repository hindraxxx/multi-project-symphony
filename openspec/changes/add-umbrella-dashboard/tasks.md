## 1. Centralized Project Workflows

- [x] 1.1 Add `workflows/personal-vercell/WORKFLOW.md` template with local clone bootstrap for `/Users/liem.sanjaya/gtf/gpl/personal-vercell`.
- [x] 1.2 Add `workflows/gtf-paylater-service/WORKFLOW.md` template with local clone bootstrap for `/Users/liem.sanjaya/gtf/gpl/gtf-paylater-service`.
- [x] 1.3 Use documented placeholder values for Linear project slugs and stable workspace roots per project.
- [x] 1.4 Document how centralized workflows differ from feature-repo-local workflow files.

## 2. Named Project Launcher

- [x] 2.1 Add a local launcher script that maps project names to workflow paths and assigned dashboard ports.
- [x] 2.2 Make the launcher start one named project through the existing `symphony-ui` flow.
- [x] 2.3 Make unknown project names fail with a concise list of valid project names.
- [x] 2.4 Add tests or shell-level verification for known and unknown launcher inputs.

## 3. Umbrella Dashboard

- [x] 3.1 Add a local umbrella dashboard entrypoint on a single port with configured project metadata.
- [x] 3.2 Fetch project status from each project's existing `/api/v1/state` endpoint server-side or through a local proxy to avoid browser cross-origin issues.
- [x] 3.3 Add a project selector that shows reachable projects and marks unavailable projects without breaking the full dashboard.
- [x] 3.4 Reuse existing status presentation patterns where practical so the umbrella view feels consistent with the current dashboard.

## 4. Verification

- [x] 4.1 Run the relevant Elixir unit tests for config, CLI, dashboard/API behavior, and any new launcher coverage.
- [x] 4.2 Manually start both project workflows on separate ports and confirm each internal dashboard/API responds.
- [x] 4.3 Start the umbrella dashboard and confirm it shows both projects, including unavailable-state behavior when one project process is stopped.
- [ ] 4.4 Run the required Codex review flow with `rtk codex review --uncommitted` after implementation changes and assess findings before completion.
  - Attempted after fixing prior review findings, but the command was interrupted by the Codex usage limit before a final review could complete.
