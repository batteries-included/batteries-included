defmodule HomeBase.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      HomeBase.Repo,
      {Phoenix.PubSub, name: HomeBase.PubSub}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: HomeBase.Supervisor)
  end
end
