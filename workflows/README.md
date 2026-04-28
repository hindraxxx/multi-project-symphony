# Symphony Project Workflows

This directory keeps project-specific Symphony workflows in the Symphony repository. Feature repositories do not need to contain `WORKFLOW.md` files for this local multi-project setup.

Each project workflow owns:

- The Linear project slug for that repository.
- The per-project workspace root.
- The bootstrap command that clones the local feature repository into each issue workspace.
- The prompt instructions sent to Codex for that project.

Replace the `TODO_*_LINEAR_PROJECT_SLUG` values before starting a project worker.

Run a single project worker with:

```bash
cd /Users/liem.sanjaya/gtf/gpl/symphony/elixir
./scripts/symphony-project personal-vercell
./scripts/symphony-project gtf-paylater-service
```

Run the local umbrella dashboard with:

```bash
cd /Users/liem.sanjaya/gtf/gpl/symphony/elixir
./scripts/symphony-umbrella
```

The project workers still run on their own localhost ports. The umbrella dashboard reads those local APIs and gives one project selector view.
