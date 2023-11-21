defmodule KubeServices.Keycloak.AdminClientSupervisor do
  @moduledoc false
  use Supervisor

  alias CommonCore.StateSummary.Creds
  alias CommonCore.StateSummary.Hosts

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  def init(_opts) do
    children = [
      # Start the supervisor that starts AdminClient with the most recent keycloak Settings
      KubeServices.Keycloak.AdminClientInnerSupervisor,
      # # Then start a genserver that monitors the system state and reconfigures if needed
      {KubeServices.SystemState.ReconfigCanary,
       [
         methods: [&Creds.root_keycloak_username/1, &Creds.root_keycloak_password/1, &Hosts.keycloak_host/1]
       ]}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
