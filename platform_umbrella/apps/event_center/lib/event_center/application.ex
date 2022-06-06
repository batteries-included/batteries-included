defmodule EventCenter.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Supervisor.child_spec(
        {Phoenix.PubSub, name: EventCenter.Database.PubSub},
        id: EventCenter.Database.PubSub
      ),
      Supervisor.child_spec(
        {Phoenix.PubSub, name: EventCenter.KubeState.PubSub},
        id: EventCenter.KubeState.PubSub
      ),
      Supervisor.child_spec(
        {Phoenix.PubSub, name: EventCenter.KubeSnapshot.PubSub},
        id: EventCenter.KubeSnapshot.PubSub
      )
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EventCenter.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
