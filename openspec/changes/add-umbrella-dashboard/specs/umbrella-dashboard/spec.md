## ADDED Requirements

### Requirement: Centralized project workflows
The system SHALL support storing project-specific Symphony workflow files under the Symphony repository while using those workflow files to operate external feature repositories.

#### Scenario: Workflow lives outside feature repository
- **WHEN** an operator starts Symphony for a named project whose workflow file is under the Symphony repository
- **THEN** Symphony SHALL load that workflow and create per-issue workspaces using the workflow's project-specific configuration

#### Scenario: Feature repository is cloned into workspace
- **WHEN** a project workflow creates a new issue workspace
- **THEN** the workflow SHALL bootstrap the workspace from the configured local feature repository path

### Requirement: Named project launcher
The system SHALL provide a local way to start a named project workflow without requiring the operator to type the full workflow path and dashboard port.

#### Scenario: Start known project
- **WHEN** an operator starts a configured project by name
- **THEN** the launcher SHALL start Symphony with that project's workflow file and assigned local dashboard port

#### Scenario: Unknown project name
- **WHEN** an operator requests an unconfigured project name
- **THEN** the launcher SHALL fail with a message listing the configured project names

### Requirement: Umbrella dashboard aggregation
The system SHALL provide a local umbrella dashboard that displays status for multiple configured project Symphony instances through a single dashboard URL.

#### Scenario: View multiple projects
- **WHEN** the umbrella dashboard loads and multiple project instances are reachable
- **THEN** it SHALL show the configured projects and allow the operator to select a project for detailed status

#### Scenario: Project instance unavailable
- **WHEN** a configured project instance cannot be reached
- **THEN** the umbrella dashboard SHALL show that project as unavailable while continuing to show other reachable projects

### Requirement: Project status source
The umbrella dashboard SHALL read project status from each project's existing Symphony status API rather than duplicating orchestration state.

#### Scenario: Project state refresh
- **WHEN** the umbrella dashboard refreshes project status
- **THEN** it SHALL fetch the configured project's status from that project's `/api/v1/state` endpoint

#### Scenario: Existing orchestration remains authoritative
- **WHEN** a project Symphony instance updates running issue state
- **THEN** the umbrella dashboard SHALL reflect that state from the project API without claiming, dispatching, or mutating issues itself
