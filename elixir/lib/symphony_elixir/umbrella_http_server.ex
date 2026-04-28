defmodule SymphonyElixir.UmbrellaHttpServer do
  @moduledoc """
  Starts the Phoenix endpoint in local umbrella-dashboard mode.
  """

  alias SymphonyElixirWeb.Endpoint

  @secret_key_bytes 48

  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    port = Keyword.get(opts, :port, Application.get_env(:symphony_elixir, :umbrella_port, 3999))
    host = Keyword.get(opts, :host, "127.0.0.1")
    projects = Keyword.get(opts, :projects, SymphonyElixir.ProjectRegistry.projects())

    with {:ok, ip} <- parse_host(host) do
      endpoint_opts = [
        server: true,
        http: [ip: ip, port: port],
        url: [host: normalize_host(host)],
        dashboard_mode: :umbrella,
        umbrella_projects: projects,
        secret_key_base: secret_key_base()
      ]

      endpoint_config =
        :symphony_elixir
        |> Application.get_env(Endpoint, [])
        |> Keyword.merge(endpoint_opts)

      Application.put_env(:symphony_elixir, Endpoint, endpoint_config)
      Endpoint.start_link()
    end
  end

  defp parse_host(host) when is_binary(host) do
    charhost = String.to_charlist(host)

    case :inet.parse_address(charhost) do
      {:ok, ip} ->
        {:ok, ip}

      {:error, _reason} ->
        case :inet.getaddr(charhost, :inet) do
          {:ok, ip} -> {:ok, ip}
          {:error, _reason} -> :inet.getaddr(charhost, :inet6)
        end
    end
  end

  defp normalize_host(host) when host in ["", nil], do: "127.0.0.1"
  defp normalize_host(host) when is_binary(host), do: host
  defp normalize_host(host), do: to_string(host)

  defp secret_key_base do
    Base.encode64(:crypto.strong_rand_bytes(@secret_key_bytes), padding: false)
  end
end
