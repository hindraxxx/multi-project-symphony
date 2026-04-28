defmodule SymphonyElixir.UmbrellaDashboard do
  @moduledoc """
  Aggregates status from local per-project Symphony instances.
  """

  @default_timeout 2_000

  @type project :: %{
          required(:name) => String.t(),
          required(:label) => String.t(),
          required(:state_url) => String.t(),
          optional(:port) => non_neg_integer(),
          optional(:workflow_path) => String.t()
        }

  @spec status_payload([project()], (String.t(), keyword() -> term())) :: map()
  def status_payload(projects, client \\ &Req.get/2) when is_list(projects) and is_function(client, 2) do
    generated_at = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
    project_payloads = fetch_project_payloads(projects, client)

    %{
      generated_at: generated_at,
      counts: aggregate_counts(project_payloads),
      projects: project_payloads
    }
  end

  defp fetch_project_payloads([], _client), do: []

  defp fetch_project_payloads(projects, client) do
    projects
    |> Task.async_stream(&project_payload(&1, client),
      max_concurrency: min(length(projects), System.schedulers_online()),
      ordered: true,
      timeout: @default_timeout + 500,
      on_timeout: :kill_task
    )
    |> Enum.zip(projects)
    |> Enum.map(fn
      {{:ok, payload}, _project} -> payload
      {{:exit, reason}, project} -> project_timeout_payload(project, reason)
    end)
  end

  defp project_payload(project, client) do
    base = base_project(project)
    url = base.state_url

    case client.(url, receive_timeout: @default_timeout) do
      {:ok, %{status: status, body: %{"error" => %{} = error}}} when status in 200..299 ->
        unavailable_project(
          base,
          to_string(error["code"] || "api_error"),
          to_string(error["message"] || "Project API returned an error payload")
        )

      {:ok, %{status: status, body: body}} when status in 200..299 and is_map(body) ->
        Map.merge(base, %{
          available: true,
          status: "available",
          counts: normalize_counts(body["counts"] || body[:counts]),
          running: normalize_list(body["running"] || body[:running]),
          retrying: normalize_list(body["retrying"] || body[:retrying]),
          codex_totals: normalize_totals(body["codex_totals"] || body[:codex_totals]),
          rate_limits: body["rate_limits"] || body[:rate_limits]
        })

      {:ok, %{status: status}} ->
        unavailable_project(base, "http_status_#{status}", "Project API returned HTTP #{status}")

      {:error, reason} ->
        unavailable_project(base, "unreachable", inspect(reason))

      other ->
        unavailable_project(base, "invalid_response", inspect(other))
    end
  end

  defp project_timeout_payload(project, reason) do
    project
    |> base_project()
    |> unavailable_project("fetch_failed", inspect(reason))
  end

  defp base_project(project) do
    %{
      name: Map.fetch!(project, :name),
      label: Map.get(project, :label, Map.fetch!(project, :name)),
      port: Map.get(project, :port),
      workflow_path: Map.get(project, :workflow_path),
      state_url: Map.fetch!(project, :state_url)
    }
  end

  defp unavailable_project(base, code, message) do
    Map.merge(base, %{
      available: false,
      status: "unavailable",
      counts: %{running: 0, retrying: 0},
      running: [],
      retrying: [],
      codex_totals: %{input_tokens: 0, output_tokens: 0, total_tokens: 0, seconds_running: 0},
      rate_limits: nil,
      error: %{code: code, message: message}
    })
  end

  defp aggregate_counts(projects) do
    %{
      total: length(projects),
      available: Enum.count(projects, & &1.available),
      unavailable: Enum.count(projects, &(not &1.available)),
      running: Enum.reduce(projects, 0, &(&1.counts.running + &2)),
      retrying: Enum.reduce(projects, 0, &(&1.counts.retrying + &2))
    }
  end

  defp normalize_counts(%{} = counts) do
    %{
      running: int_value(counts["running"] || counts[:running]),
      retrying: int_value(counts["retrying"] || counts[:retrying])
    }
  end

  defp normalize_counts(_counts), do: %{running: 0, retrying: 0}

  defp normalize_totals(%{} = totals) do
    %{
      input_tokens: int_value(totals["input_tokens"] || totals[:input_tokens]),
      output_tokens: int_value(totals["output_tokens"] || totals[:output_tokens]),
      total_tokens: int_value(totals["total_tokens"] || totals[:total_tokens]),
      seconds_running: number_value(totals["seconds_running"] || totals[:seconds_running])
    }
  end

  defp normalize_totals(_totals),
    do: %{input_tokens: 0, output_tokens: 0, total_tokens: 0, seconds_running: 0}

  defp normalize_list(value) when is_list(value), do: value
  defp normalize_list(_value), do: []

  defp int_value(value) when is_integer(value), do: value
  defp int_value(value) when is_float(value), do: trunc(value)
  defp int_value(_value), do: 0

  defp number_value(value) when is_number(value), do: value
  defp number_value(_value), do: 0
end
