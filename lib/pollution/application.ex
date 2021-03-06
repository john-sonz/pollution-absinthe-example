defmodule Pollution.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      PollutionWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Pollution.PubSub},
      # Start the Endpoint (http/https)
      PollutionWeb.Endpoint,
      # Start the Absinthe subscriptions supervisor
      {Absinthe.Subscription, PollutionWeb.Endpoint},
      # Start the pollution GenServer
      %{
        id: Pollution.Server,
        start: {Pollution.Server, :start_link, []}
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Pollution.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    PollutionWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
