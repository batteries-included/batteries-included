defmodule KubeServices.Keycloak.AdminClientSupervisor do
  @moduledoc false
  use Supervisor

  alias CommonCore.StateSummary.Creds
  alias CommonCore.StateSummary.URLs

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  def init(_opts) do
    children = [
      # # Start a genserver that monitors the system state and reconfigures if needed
      {KubeServices.SystemState.ReconfigCanary,
       [
         methods: [&Creds.root_keycloak_username/1, &Creds.root_keycloak_password/1, &keycloak_base_url/1]
       ]},
      # Start the supervisor that starts AdminClient with the most recent keycloak Settings
      KubeServices.Keycloak.AdminClientInnerSupervisor
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  def keycloak_base_url(state) do
    state |> URLs.uri_for_battery(:keycloak) |> URI.to_string()
  end
end
