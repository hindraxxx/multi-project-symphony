defmodule SymphonyElixir.ProjectRegistry do
  @moduledoc """
  Static local project registry for multi-project Symphony operations.
  """

  @repo_root Path.expand("../../..", __DIR__)

  @projects [
    %{
      name: "personal-vercell",
      label: "personal-vercell",
      workflow_path: Path.join(@repo_root, "workflows/personal-vercell/WORKFLOW.md"),
      port: 4000,
      state_url: "http://127.0.0.1:4000/api/v1/state"
    },
    %{
      name: "gtf-paylater-service",
      label: "gtf-paylater-service",
      workflow_path: Path.join(@repo_root, "workflows/gtf-paylater-service/WORKFLOW.md"),
      port: 4001,
      state_url: "http://127.0.0.1:4001/api/v1/state"
    }
  ]

  @spec projects() :: [map()]
  def projects, do: @projects

  @spec names() :: [String.t()]
  def names, do: Enum.map(@projects, & &1.name)
end
