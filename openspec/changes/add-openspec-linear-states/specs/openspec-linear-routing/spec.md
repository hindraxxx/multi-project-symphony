## ADDED Requirements

### Requirement: Workflow recognizes OpenSpec routing states
The Symphony workflow SHALL recognize `OpenSpec Explore` and `OpenSpec Propose` as active Linear states when those exact state names are configured in `active_states`.

#### Scenario: OpenSpec Explore is active
- **WHEN** a Linear issue is in state `OpenSpec Explore`
- **THEN** Symphony SHALL treat the issue as eligible for an agent run using the OpenSpec Explore routing behavior

#### Scenario: OpenSpec Propose is active
- **WHEN** a Linear issue is in state `OpenSpec Propose`
- **THEN** Symphony SHALL treat the issue as eligible for an agent run using the OpenSpec Propose routing behavior

### Requirement: Explore state does not implement or auto-advance
When an issue is in `OpenSpec Explore`, the agent SHALL perform discovery and capture findings without writing application implementation code or moving the issue to another state.

#### Scenario: Explore completes
- **WHEN** the agent completes an `OpenSpec Explore` run
- **THEN** the issue SHALL remain in `OpenSpec Explore` for the user to manually route next

### Requirement: Propose state creates OpenSpec artifacts only
When an issue is in `OpenSpec Propose`, the agent SHALL create the OpenSpec proposal artifacts required for implementation readiness and SHALL NOT implement application changes or move the issue to another state.

#### Scenario: Propose completes
- **WHEN** the agent completes an `OpenSpec Propose` run
- **THEN** the issue SHALL remain in `OpenSpec Propose` for the user to manually route next

### Requirement: In Progress applies existing OpenSpec changes when present
When an issue is in `In Progress`, the agent SHALL use the OpenSpec apply workflow if the issue explicitly references an existing OpenSpec change; otherwise it SHALL follow the direct implementation workflow.

#### Scenario: In Progress with referenced OpenSpec change
- **WHEN** an `In Progress` issue references an existing OpenSpec change
- **THEN** the agent SHALL run the OpenSpec apply workflow for that change

#### Scenario: In Progress without referenced OpenSpec change
- **WHEN** an `In Progress` issue does not reference an existing OpenSpec change
- **THEN** the agent SHALL use the direct implementation workflow

### Requirement: User controls OpenSpec route selection
The workflow SHALL NOT infer that a ticket needs OpenSpec Explore or OpenSpec Propose based only on ticket size, ambiguity, labels, or wording.

#### Scenario: Ambiguous ticket in In Progress
- **WHEN** an ambiguous issue is manually moved to `In Progress` without an explicit OpenSpec change reference
- **THEN** the agent SHALL either implement directly if requirements are sufficient or report a blocker if clarification is required, without creating an OpenSpec proposal automatically
