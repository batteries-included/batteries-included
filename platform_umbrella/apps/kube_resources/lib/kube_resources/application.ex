defmodule KubeResources.Application do
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = []

    opts = [strategy: :one_for_one, name: KubeResources.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
