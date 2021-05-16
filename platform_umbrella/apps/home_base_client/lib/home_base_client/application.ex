defmodule HomeBaseClient.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: HomeBaseClient.EventCenter.PubSub},
      # Starts a worker by calling: HomeBaseClient.Worker.start_link(arg)
      {HomeBaseClient.Reporter, name: HomeBaseClient.Reporter}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HomeBaseClient.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
