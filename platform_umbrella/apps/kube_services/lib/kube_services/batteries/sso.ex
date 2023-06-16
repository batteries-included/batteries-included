defmodule KubeServices.Batteries.SSO do
  use KubeServices.Batteries.Supervisor

  require Logger

  def init(opts) do
    _battery = Keyword.fetch!(opts, :battery)

    children = [KubeServices.Keycloak.Wrangler, KubeServices.SnapshotApply.KeycloakApply]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
