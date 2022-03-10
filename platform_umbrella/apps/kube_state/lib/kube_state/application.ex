defmodule KubeState.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: KubeState.Worker.start_link(arg)
      # {KubeState.Worker, arg}
      {KubeState.Runner, name: KubeState.default_state_table()}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: KubeState.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
