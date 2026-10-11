defmodule Time_manager.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Time_managerWeb.Telemetry,
      Time_manager.Repo,
      Time_manager.RateLimiter,
      {DNSCluster, query: Application.get_env(:manager, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Time_manager.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Time_manager.Finch},
      # Start a worker by calling: Time_manager.Worker.start_link(arg)
      # {Time_manager.Worker, arg},
      # Start to serve requests, typically the last entry
      Time_managerWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Time_manager.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    Time_managerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
