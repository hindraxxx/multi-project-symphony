## Context

Symphony currently treats configured Linear `active_states` as eligible work and the workflow prompt routes tickets by the exact Linear state name. The primary workflow moves `Todo` tickets into `In Progress` and then runs implementation, validation, PR creation, and handoff to `Human Review`.

The desired model keeps the user's manual Linear transition as the source of intent. Small tickets can move directly to `In Progress`, while larger or unclear tickets can be moved to `OpenSpec Explore` or `OpenSpec Propose` for pre-implementation work.

## Goals / Non-Goals

**Goals:**

- Add `OpenSpec Explore` and `OpenSpec Propose` as recognized active workflow states.
- Make both states non-implementation states that stop after producing their intended output.
- Keep state advancement manual after Explore and Propose.
- Make `In Progress` choose between direct implementation and `openspec apply` based on whether an OpenSpec change exists for the ticket.
- Document the required Linear state setup and exact-name matching.

**Non-Goals:**

- Do not make the agent decide when a ticket deserves Explore or Propose.
- Do not auto-transition from Explore to Propose, or from Propose to In Progress.
- Do not change the OpenSpec CLI or schema behavior.
- Do not introduce new tracker APIs beyond existing state-name routing.

## Decisions

1. Use Linear states as the user intent signal.

   The workflow will route on `issue.state` names: `OpenSpec Explore`, `OpenSpec Propose`, and `In Progress`. This keeps the decision visible on the Linear board and avoids hidden heuristics.

   Alternative considered: infer OpenSpec needs from ticket size, labels, or wording. This was rejected because it could surprise the user and route simple work into unnecessary process.

2. Keep Explore and Propose human-gated.

   After completing Explore or Propose output, the agent should leave the issue in the current state and report what was produced. The user manually moves the issue to the next state.

   Alternative considered: auto-advance when enough information exists. This was rejected because Explore and Propose are decision gates, not implementation phases.

3. Keep implementation entry in `In Progress`.

   `In Progress` remains the only normal implementation state. If a ticket references or has a matching OpenSpec change, the agent runs the apply workflow; otherwise it performs direct implementation.

   Alternative considered: add a separate `OpenSpec Apply` Linear state. This was rejected for now to keep the Linear workflow smaller and because implementation remains the same lifecycle phase.

4. Prefer explicit OpenSpec change references.

   The workflow should first look for a clear ticket reference such as `OpenSpec change: add-openspec-linear-states`. Title/name matching can be a fallback, but exact references are safer.

## Risks / Trade-offs

- State names can drift between Linear and `WORKFLOW.md` -> Document exact-name matching and include both new names in `active_states`.
- Leaving `Todo` active may still auto-start tickets before the user routes them -> Recommend making `Todo` a staging state or using `Backlog`/manual moves if strict manual control is desired.
- Explore output can become ambiguous if there is no durable artifact target -> Use the existing workpad/comment pattern or OpenSpec artifacts only when the state calls for proposal generation.
- Auto-detecting matching OpenSpec changes can be wrong -> Prefer explicit references and only use heuristic matching as a fallback.
