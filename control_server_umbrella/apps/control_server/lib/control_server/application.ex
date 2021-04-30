defmodule ControlServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      ControlServer.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: ControlServer.PubSub}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ControlServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
