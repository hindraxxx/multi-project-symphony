## 1. Workflow Configuration

- [x] 1.1 Add `OpenSpec Explore` and `OpenSpec Propose` to the relevant `active_states` in `elixir/WORKFLOW.md`.
- [x] 1.2 Decide and document whether `Todo` remains active or becomes a staging-only state for manual routing.

## 2. Routing Prompt Updates

- [x] 2.1 Add status map entries for `OpenSpec Explore` and `OpenSpec Propose`.
- [x] 2.2 Add a routing flow for `OpenSpec Explore` that performs discovery only, captures findings, and does not implement or auto-advance.
- [x] 2.3 Add a routing flow for `OpenSpec Propose` that creates OpenSpec artifacts only and does not implement or auto-advance.
- [x] 2.4 Update `In Progress` routing to run OpenSpec apply when an explicit existing OpenSpec change is referenced, otherwise use direct implementation.
- [x] 2.5 Add guardrails preventing automatic Explore/Propose creation from ambiguous or large tickets outside the selected states.

## 3. Documentation And Validation

- [x] 3.1 Document the required Linear statuses and exact-name matching in workflow-facing documentation.
- [x] 3.2 Update any relevant spec or README text if the workflow contract changes meaningfully.
- [x] 3.3 Validate the OpenSpec change with `openspec validate add-openspec-linear-states --strict`.
- [x] 3.4 Run the relevant Elixir formatting/spec checks for touched workflow or documentation behavior if applicable.
