defmodule KubeServices.Batteries.SSO do
  @moduledoc false
  use KubeServices.Batteries.Supervisor

  require Logger

  def init(opts) do
    _battery = Keyword.fetch!(opts, :battery)

    children = [
      KubeServices.SnapshotApply.KeycloakApply
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
