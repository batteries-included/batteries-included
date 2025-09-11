defmodule KubeServices.Batteries do
  @moduledoc false
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    children = [
      KubeServices.Batteries.Registry,
      {DynamicSupervisor, strategy: :one_for_one, name: KubeServices.Batteries.DynamicSupervisor},
      KubeServices.Batteries.InstalledWatcher
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def via(%{id: id} = _battery) do
    {:via, Registry, {KubeServices.Batteries.Registry, id}}
  end
end
