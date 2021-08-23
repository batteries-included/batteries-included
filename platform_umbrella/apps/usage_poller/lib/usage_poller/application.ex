defmodule UsagePoller.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {UsagePoller, name: UsagePoller}
    ]

    opts = [strategy: :one_for_one, name: UsagePoller.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
