defmodule KubeServices.Batteries.Keycloak do
  @moduledoc false
  use KubeServices.Batteries.Supervisor

  alias KubeServices.Keycloak.AdminClientSupervisor

  require Logger

  def init(opts) do
    _battery = Keyword.fetch!(opts, :battery)

    Logger.info("Starting Keycloak supervision tree")

    children = [
      # Start the AdminClient
      AdminClientSupervisor,
      # After we know the admin client is up and running, start the user manager
      KubeServices.Keycloak.UserManager,
      KubeServices.SnapshotApply.KeycloakApply,
      # A genserver the watches for failed Keycloak applys.
      # Starting a new attempt with increasing delays.
      {KubeServices.SnapshotApply.FailedKeycloakLauncher, max_delay: 91_237}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
