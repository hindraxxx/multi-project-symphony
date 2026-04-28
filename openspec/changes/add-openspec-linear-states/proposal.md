## Why

Teams need a human-controlled way to route larger or ambiguous Linear tickets through OpenSpec discovery and proposal generation before implementation. The current workflow starts `Todo` tickets directly into implementation, which makes it hard for the user to choose when a ticket should be explored or formally proposed first.

## What Changes

- Add support for user-selected Linear states `OpenSpec Explore` and `OpenSpec Propose` in the Symphony workflow contract.
- Define `OpenSpec Explore` as a discovery-only state that may inspect context and capture thinking, but must not implement or auto-advance the ticket.
- Define `OpenSpec Propose` as an artifact-generation-only state that creates OpenSpec proposal/design/spec/tasks as needed, but must not implement or auto-advance the ticket.
- Update `In Progress` routing so tickets with an existing linked OpenSpec change use `openspec apply`; tickets without one continue through direct implementation.
- Preserve manual human control over transitions between OpenSpec states and implementation.

## Capabilities

### New Capabilities
- `openspec-linear-routing`: Defines how Symphony routes Linear issues through optional OpenSpec Explore, OpenSpec Propose, and Apply paths under human-selected states.

### Modified Capabilities

None.

## Impact

- `elixir/WORKFLOW.md` prompt and front matter active state list.
- Workflow documentation for Linear state setup and expected routing behavior.
- Potential tests or fixtures that assert workflow config/prompt behavior.
