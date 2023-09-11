defmodule EventCenter.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children =
      Enum.map(
        [
          EventCenter.Database.PubSub,
          EventCenter.KubeState.PubSub,
          EventCenter.KubeSnapshot.PubSub,
          EventCenter.SystemStateSummary.PubSub,
          EventCenter.Keycloak.Pubsub
        ],
        fn mod -> Supervisor.child_spec({Phoenix.PubSub, name: mod}, id: mod) end
      )

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EventCenter.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
