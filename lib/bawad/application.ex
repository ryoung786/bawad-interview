defmodule Bawad.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      BawadWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Bawad.PubSub},
      # Start the Endpoint (http/https)
      BawadWeb.Endpoint
      # Start a worker by calling: Bawad.Worker.start_link(arg)
      # {Bawad.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Bawad.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    BawadWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
