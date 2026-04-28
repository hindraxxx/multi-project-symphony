defmodule SymphonyElixirWeb.DashboardLive do
  @moduledoc """
  Live observability dashboard for Symphony.
  """

  use Phoenix.LiveView, layout: {SymphonyElixirWeb.Layouts, :app}

  alias SymphonyElixir.UmbrellaDashboard
  alias SymphonyElixirWeb.{Endpoint, ObservabilityPubSub, Presenter}
  @runtime_tick_ms 1_000

  @impl true
  def mount(_params, _session, socket) do
    socket =
      assign_initial_payload(socket)
      |> assign(:now, DateTime.utc_now())

    if connected?(socket) do
      unless umbrella_mode?(), do: :ok = ObservabilityPubSub.subscribe()
      schedule_runtime_tick()
    end

    {:ok, socket}
  end

  @impl true
  def handle_info(:runtime_tick, socket) do
    schedule_runtime_tick()

    socket =
      socket
      |> maybe_reload_umbrella_payload()
      |> assign(:now, DateTime.utc_now())

    {:noreply, socket}
  end

  @impl true
  def handle_info(:observability_updated, socket) do
    {:noreply,
     socket
     |> assign(:payload, load_payload())
     |> assign(:now, DateTime.utc_now())}
  end

  @impl true
  def render(assigns) do
    if Map.get(assigns, :dashboard_mode) == :umbrella do
      render_umbrella(assigns)
    else
      render_runtime(assigns)
    end
  end

  defp render_runtime(assigns) do
    ~H"""
    <section class="dashboard-shell">
      <header class="hero-card">
        <div class="hero-grid">
          <div>
            <p class="eyebrow">
              Symphony Observability
            </p>
            <h1 class="hero-title">
              Operations Dashboard
            </h1>
            <p class="hero-copy">
              Current state, retry pressure, token usage, and orchestration health for the active Symphony runtime.
            </p>
          </div>

          <div class="status-stack">
            <span class="status-badge status-badge-live">
              <span class="status-badge-dot"></span>
              Live
            </span>
            <span class="status-badge status-badge-offline">
              <span class="status-badge-dot"></span>
              Offline
            </span>
          </div>
        </div>
      </header>

      <%= if @payload[:error] do %>
        <section class="error-card">
          <h2 class="error-title">
            Snapshot unavailable
          </h2>
          <p class="error-copy">
            <strong><%= @payload.error.code %>:</strong> <%= @payload.error.message %>
          </p>
        </section>
      <% else %>
        <section class="metric-grid">
          <article class="metric-card">
            <p class="metric-label">Running</p>
            <p class="metric-value numeric"><%= @payload.counts.running %></p>
            <p class="metric-detail">Active issue sessions in the current runtime.</p>
          </article>

          <article class="metric-card">
            <p class="metric-label">Retrying</p>
            <p class="metric-value numeric"><%= @payload.counts.retrying %></p>
            <p class="metric-detail">Issues waiting for the next retry window.</p>
          </article>

          <article class="metric-card">
            <p class="metric-label">Total tokens</p>
            <p class="metric-value numeric"><%= format_int(@payload.codex_totals.total_tokens) %></p>
            <p class="metric-detail numeric">
              In <%= format_int(@payload.codex_totals.input_tokens) %> / Out <%= format_int(@payload.codex_totals.output_tokens) %>
            </p>
          </article>

          <article class="metric-card">
            <p class="metric-label">Runtime</p>
            <p class="metric-value numeric"><%= format_runtime_seconds(total_runtime_seconds(@payload, @now)) %></p>
            <p class="metric-detail">Total Codex runtime across completed and active sessions.</p>
          </article>
        </section>

        <section class="section-card">
          <div class="section-header">
            <div>
              <h2 class="section-title">Rate limits</h2>
              <p class="section-copy">Latest upstream rate-limit snapshot, when available.</p>
            </div>
          </div>

          <pre class="code-panel"><%= pretty_value(@payload.rate_limits) %></pre>
        </section>

        <section class="section-card">
          <div class="section-header">
            <div>
              <h2 class="section-title">Running sessions</h2>
              <p class="section-copy">Active issues, last known agent activity, and token usage.</p>
            </div>
          </div>

          <%= if @payload.running == [] do %>
            <p class="empty-state">No active sessions.</p>
          <% else %>
            <div class="table-wrap">
              <table class="data-table data-table-running">
                <colgroup>
                  <col style="width: 12rem;" />
                  <col style="width: 8rem;" />
                  <col style="width: 7.5rem;" />
                  <col style="width: 8.5rem;" />
                  <col />
                  <col style="width: 10rem;" />
                </colgroup>
                <thead>
                  <tr>
                    <th>Issue</th>
                    <th>State</th>
                    <th>Session</th>
                    <th>Runtime / turns</th>
                    <th>Codex update</th>
                    <th>Tokens</th>
                  </tr>
                </thead>
                <tbody>
                  <tr :for={entry <- @payload.running}>
                    <td>
                      <div class="issue-stack">
                        <span class="issue-id"><%= entry.issue_identifier %></span>
                        <a class="issue-link" href={"/api/v1/#{entry.issue_identifier}"}>JSON details</a>
                      </div>
                    </td>
                    <td>
                      <span class={state_badge_class(entry.state)}>
                        <%= entry.state %>
                      </span>
                    </td>
                    <td>
                      <div class="session-stack">
                        <%= if entry.session_id do %>
                          <button
                            type="button"
                            class="subtle-button"
                            data-label="Copy ID"
                            data-copy={entry.session_id}
                            onclick="navigator.clipboard.writeText(this.dataset.copy); this.textContent = 'Copied'; clearTimeout(this._copyTimer); this._copyTimer = setTimeout(() => { this.textContent = this.dataset.label }, 1200);"
                          >
                            Copy ID
                          </button>
                        <% else %>
                          <span class="muted">n/a</span>
                        <% end %>
                      </div>
                    </td>
                    <td class="numeric"><%= format_runtime_and_turns(entry.started_at, entry.turn_count, @now) %></td>
                    <td>
                      <div class="detail-stack">
                        <span
                          class="event-text"
                          title={entry.last_message || to_string(entry.last_event || "n/a")}
                        ><%= entry.last_message || to_string(entry.last_event || "n/a") %></span>
                        <span class="muted event-meta">
                          <%= entry.last_event || "n/a" %>
                          <%= if entry.last_event_at do %>
                            · <span class="mono numeric"><%= entry.last_event_at %></span>
                          <% end %>
                        </span>
                      </div>
                    </td>
                    <td>
                      <div class="token-stack numeric">
                        <span>Total: <%= format_int(entry.tokens.total_tokens) %></span>
                        <span class="muted">In <%= format_int(entry.tokens.input_tokens) %> / Out <%= format_int(entry.tokens.output_tokens) %></span>
                      </div>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          <% end %>
        </section>

        <section class="section-card">
          <div class="section-header">
            <div>
              <h2 class="section-title">Retry queue</h2>
              <p class="section-copy">Issues waiting for the next retry window.</p>
            </div>
          </div>

          <%= if @payload.retrying == [] do %>
            <p class="empty-state">No issues are currently backing off.</p>
          <% else %>
            <div class="table-wrap">
              <table class="data-table" style="min-width: 680px;">
                <thead>
                  <tr>
                    <th>Issue</th>
                    <th>Attempt</th>
                    <th>Due at</th>
                    <th>Error</th>
                  </tr>
                </thead>
                <tbody>
                  <tr :for={entry <- @payload.retrying}>
                    <td>
                      <div class="issue-stack">
                        <span class="issue-id"><%= entry.issue_identifier %></span>
                        <a class="issue-link" href={"/api/v1/#{entry.issue_identifier}"}>JSON details</a>
                      </div>
                    </td>
                    <td><%= entry.attempt %></td>
                    <td class="mono"><%= entry.due_at || "n/a" %></td>
                    <td><%= entry.error || "n/a" %></td>
                  </tr>
                </tbody>
              </table>
            </div>
          <% end %>
        </section>
      <% end %>
    </section>
    """
  end

  defp render_umbrella(assigns) do
    ~H"""
    <section class="dashboard-shell">
      <header class="hero-card">
        <div class="hero-grid">
          <div>
            <p class="eyebrow">
              Symphony Umbrella
            </p>
            <h1 class="hero-title">
              Project Dashboard
            </h1>
            <p class="hero-copy">
              One local view over project-specific Symphony workers. Worker ports stay separate; this page reads their local status APIs.
            </p>
          </div>

          <div class="status-stack">
            <span class="status-badge status-badge-live">
              <span class="status-badge-dot"></span>
              Live
            </span>
            <span class="status-badge status-badge-offline">
              <span class="status-badge-dot"></span>
              Offline
            </span>
          </div>
        </div>
      </header>

      <section class="metric-grid">
        <article class="metric-card">
          <p class="metric-label">Projects</p>
          <p class="metric-value numeric"><%= @umbrella_payload.counts.available %>/<%= @umbrella_payload.counts.total %></p>
          <p class="metric-detail">Reachable project workers.</p>
        </article>

        <article class="metric-card">
          <p class="metric-label">Running</p>
          <p class="metric-value numeric"><%= @umbrella_payload.counts.running %></p>
          <p class="metric-detail">Active sessions across reachable projects.</p>
        </article>

        <article class="metric-card">
          <p class="metric-label">Retrying</p>
          <p class="metric-value numeric"><%= @umbrella_payload.counts.retrying %></p>
          <p class="metric-detail">Queued retries across reachable projects.</p>
        </article>

        <article class="metric-card">
          <p class="metric-label">Updated</p>
          <p class="metric-value metric-value-compact numeric"><%= @umbrella_payload.generated_at %></p>
          <p class="metric-detail">Status refresh timestamp.</p>
        </article>
      </section>

      <section class="section-card">
        <div class="section-header">
          <div>
            <h2 class="section-title">Projects</h2>
            <p class="section-copy">Select a project worker to inspect its current sessions.</p>
          </div>
        </div>

        <div class="project-selector">
          <a
            :for={project <- @umbrella_payload.projects}
            class={project_selector_class(project, @selected_project)}
            href={"?project=#{project.name}"}
          >
            <span class="project-selector-title"><%= project.label %></span>
            <span class={if project.available, do: "state-badge state-badge-active", else: "state-badge state-badge-danger"}>
              <%= project.status %>
            </span>
          </a>
        </div>
      </section>

      <%= if @selected_project do %>
        <section class="section-card">
          <div class="section-header">
            <div>
              <h2 class="section-title"><%= @selected_project.label %></h2>
              <p class="section-copy">
                <span class="mono"><%= @selected_project.state_url %></span>
              </p>
            </div>

            <a class="issue-link" href={@selected_project.state_url}>Raw state JSON</a>
          </div>

          <%= if @selected_project.available do %>
            <section class="metric-grid metric-grid-inner">
              <article class="metric-card">
                <p class="metric-label">Running</p>
                <p class="metric-value numeric"><%= @selected_project.counts.running %></p>
              </article>
              <article class="metric-card">
                <p class="metric-label">Retrying</p>
                <p class="metric-value numeric"><%= @selected_project.counts.retrying %></p>
              </article>
              <article class="metric-card">
                <p class="metric-label">Total tokens</p>
                <p class="metric-value numeric"><%= format_int(@selected_project.codex_totals.total_tokens) %></p>
              </article>
            </section>

            <div class="table-wrap">
              <table class="data-table data-table-running">
                <colgroup>
                  <col style="width: 12rem;" />
                  <col style="width: 8rem;" />
                  <col />
                  <col style="width: 10rem;" />
                </colgroup>
                <thead>
                  <tr>
                    <th>Issue</th>
                    <th>State</th>
                    <th>Codex update</th>
                    <th>Tokens</th>
                  </tr>
                </thead>
                <tbody>
                  <tr :for={entry <- @selected_project.running}>
                    <td>
                      <div class="issue-stack">
                        <span class="issue-id"><%= entry_value(entry, "issue_identifier") %></span>
                        <span class="muted mono"><%= entry_value(entry, "session_id") || "n/a" %></span>
                      </div>
                    </td>
                    <td>
                      <span class={state_badge_class(entry_value(entry, "state"))}>
                        <%= entry_value(entry, "state") || "n/a" %>
                      </span>
                    </td>
                    <td>
                      <div class="detail-stack">
                        <span class="event-text"><%= entry_value(entry, "last_message") || entry_value(entry, "last_event") || "n/a" %></span>
                      </div>
                    </td>
                    <td>
                      <div class="token-stack numeric">
                        <span>Total: <%= format_int(entry_tokens(entry, "total_tokens")) %></span>
                        <span class="muted">In <%= format_int(entry_tokens(entry, "input_tokens")) %> / Out <%= format_int(entry_tokens(entry, "output_tokens")) %></span>
                      </div>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>

            <%= if @selected_project.running == [] do %>
              <p class="empty-state">No active sessions for this project.</p>
            <% end %>
          <% else %>
            <section class="error-card">
              <h2 class="error-title">Project unavailable</h2>
              <p class="error-copy">
                <strong><%= @selected_project.error.code %>:</strong> <%= @selected_project.error.message %>
              </p>
            </section>
          <% end %>
        </section>
      <% end %>
    </section>
    """
  end

  @impl true
  def handle_params(params, _uri, %{assigns: %{dashboard_mode: :umbrella}} = socket) do
    selected_name = params["project"]
    {:noreply, assign_selected_project(socket, selected_name)}
  end

  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  defp assign_initial_payload(socket) do
    case dashboard_mode() do
      :umbrella ->
        payload = load_umbrella_payload()

        socket
        |> assign(:dashboard_mode, :umbrella)
        |> assign(:umbrella_payload, payload)
        |> assign(:selected_project, List.first(payload.projects))

      _ ->
        socket
        |> assign(:dashboard_mode, :runtime)
        |> assign(:payload, load_payload())
    end
  end

  defp maybe_reload_umbrella_payload(%{assigns: %{dashboard_mode: :umbrella}} = socket) do
    selected_name = socket.assigns.selected_project && socket.assigns.selected_project.name
    payload = load_umbrella_payload()

    socket
    |> assign(:umbrella_payload, payload)
    |> assign_selected_project(selected_name)
  end

  defp maybe_reload_umbrella_payload(socket), do: socket

  defp assign_selected_project(socket, selected_name) do
    projects = socket.assigns.umbrella_payload.projects

    selected =
      Enum.find(projects, &(selected_name && &1.name == selected_name)) ||
        List.first(projects)

    assign(socket, :selected_project, selected)
  end

  defp load_umbrella_payload do
    UmbrellaDashboard.status_payload(umbrella_projects())
  end

  defp umbrella_projects do
    Endpoint.config(:umbrella_projects) || SymphonyElixir.ProjectRegistry.projects()
  end

  defp umbrella_mode?, do: dashboard_mode() == :umbrella

  defp dashboard_mode do
    Endpoint.config(:dashboard_mode) || :runtime
  end

  defp load_payload do
    Presenter.state_payload(orchestrator(), snapshot_timeout_ms())
  end

  defp orchestrator do
    Endpoint.config(:orchestrator) || SymphonyElixir.Orchestrator
  end

  defp snapshot_timeout_ms do
    Endpoint.config(:snapshot_timeout_ms) || 15_000
  end

  defp completed_runtime_seconds(payload) do
    payload.codex_totals.seconds_running || 0
  end

  defp total_runtime_seconds(payload, now) do
    completed_runtime_seconds(payload) +
      Enum.reduce(payload.running, 0, fn entry, total ->
        total + runtime_seconds_from_started_at(entry.started_at, now)
      end)
  end

  defp format_runtime_and_turns(started_at, turn_count, now) when is_integer(turn_count) and turn_count > 0 do
    "#{format_runtime_seconds(runtime_seconds_from_started_at(started_at, now))} / #{turn_count}"
  end

  defp format_runtime_and_turns(started_at, _turn_count, now),
    do: format_runtime_seconds(runtime_seconds_from_started_at(started_at, now))

  defp format_runtime_seconds(seconds) when is_number(seconds) do
    whole_seconds = max(trunc(seconds), 0)
    mins = div(whole_seconds, 60)
    secs = rem(whole_seconds, 60)
    "#{mins}m #{secs}s"
  end

  defp runtime_seconds_from_started_at(%DateTime{} = started_at, %DateTime{} = now) do
    DateTime.diff(now, started_at, :second)
  end

  defp runtime_seconds_from_started_at(started_at, %DateTime{} = now) when is_binary(started_at) do
    case DateTime.from_iso8601(started_at) do
      {:ok, parsed, _offset} -> runtime_seconds_from_started_at(parsed, now)
      _ -> 0
    end
  end

  defp runtime_seconds_from_started_at(_started_at, _now), do: 0

  defp format_int(value) when is_integer(value) do
    value
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/.{3}(?=.)/, "\\0,")
    |> String.reverse()
  end

  defp format_int(_value), do: "n/a"

  defp state_badge_class(state) do
    base = "state-badge"
    normalized = state |> to_string() |> String.downcase()

    cond do
      String.contains?(normalized, ["progress", "running", "active"]) -> "#{base} state-badge-active"
      String.contains?(normalized, ["blocked", "error", "failed"]) -> "#{base} state-badge-danger"
      String.contains?(normalized, ["todo", "queued", "pending", "retry"]) -> "#{base} state-badge-warning"
      true -> base
    end
  end

  defp project_selector_class(project, selected_project) do
    base = "project-selector-item"

    if selected_project && project.name == selected_project.name do
      "#{base} project-selector-item-active"
    else
      base
    end
  end

  defp entry_value(entry, key) when is_map(entry) do
    entry[key] || entry[String.to_atom(key)]
  rescue
    ArgumentError -> entry[key]
  end

  defp entry_tokens(entry, key) when is_map(entry) do
    case entry_value(entry, "tokens") do
      %{} = tokens -> tokens[key] || tokens[String.to_atom(key)] || 0
      _ -> 0
    end
  rescue
    ArgumentError -> 0
  end

  defp schedule_runtime_tick do
    Process.send_after(self(), :runtime_tick, @runtime_tick_ms)
  end

  defp pretty_value(nil), do: "n/a"
  defp pretty_value(value), do: inspect(value, pretty: true, limit: :infinity)
end
