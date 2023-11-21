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
      KubeServices.Keycloak.UserManager
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
