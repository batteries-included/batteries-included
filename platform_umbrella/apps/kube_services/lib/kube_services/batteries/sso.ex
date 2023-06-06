defmodule KubeServices.Batteries.SSO do
  use KubeServices.Batteries.Supervisor

  alias KubeServices.SystemState.SummaryHosts

  require Logger

  def init(opts) do
    _battery = Keyword.fetch!(opts, :battery)

    children = [
      {KubeServices.Keycloak.AdminClient,
       [
         username: "batteryadmin",
         password: "testing",
         base_url: "http://" <> SummaryHosts.keycloak_host()
       ]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
