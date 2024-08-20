defmodule EmojiGraffiti.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      EmojiGraffitiWeb.Telemetry,
      EmojiGraffiti.Repo,
      EmojiGraffiti.Wall,
      {DNSCluster, query: Application.get_env(:emoji_graffiti, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: EmojiGraffiti.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: EmojiGraffiti.Finch},
      # Start a worker by calling: EmojiGraffiti.Worker.start_link(arg)
      # {EmojiGraffiti.Worker, arg},
      # Start to serve requests, typically the last entry
      EmojiGraffitiWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EmojiGraffiti.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    EmojiGraffitiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
