defmodule Xinfeng.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      XinfengWeb.Telemetry,
      Xinfeng.Repo,
      {DNSCluster, query: Application.get_env(:xinfeng, :dns_cluster_query) || :ignore},
      {Oban, Application.fetch_env!(:xinfeng, Oban)},
      {Phoenix.PubSub, name: Xinfeng.PubSub},
      # Start a worker by calling: Xinfeng.Worker.start_link(arg)
      # {Xinfeng.Worker, arg},
      # Start to serve requests, typically the last entry
      XinfengWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Xinfeng.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    XinfengWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
