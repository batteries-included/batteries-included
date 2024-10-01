defmodule KubeServices.Timeline do
  @moduledoc false
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    children = [
      KubeServices.Timeline.Database,
      KubeServices.Timeline.Battery,
      KubeServices.Timeline.Keycloak,
      KubeServices.Timeline.Kube
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
