defmodule KubeServices.Batteries.SSO do
  @moduledoc false
  use KubeServices.Batteries.Supervisor

  require Logger

  def init(opts) do
    _battery = Keyword.fetch!(opts, :battery)

    children = [
      KubeServices.SnapshotApply.KeycloakApply,
      KubeServices.Keycloak.OIDCSupervisor,
      # A genserver the watches for failed Keycloak applys.
      # Starting a new attempt with increasing delays.
      {KubeServices.SnapshotApply.FailedKeycloakLauncher, max_delay: 91_237}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
