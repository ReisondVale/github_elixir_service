defmodule GithubElixirService.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      GithubElixirServiceWeb.Telemetry,
      GithubElixirService.Repo,
      {DNSCluster,
       query: Application.get_env(:github_elixir_service, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: GithubElixirService.PubSub},
      {Oban, Application.fetch_env!(:github_elixir_service, Oban)},
      # Start the Finch HTTP client for sending emails
      {Finch, name: GithubElixirService.Finch},
      # Start a worker by calling: GithubElixirService.Worker.start_link(arg)
      # {GithubElixirService.Worker, arg},
      # Start to serve requests, typically the last entry
      GithubElixirServiceWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GithubElixirService.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    GithubElixirServiceWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
