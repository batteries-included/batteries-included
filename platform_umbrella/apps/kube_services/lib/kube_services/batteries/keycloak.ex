defmodule KubeServices.Batteries.Keycloak do
  @moduledoc false
  use KubeServices.Batteries.Supervisor

  require Logger

  def init(opts) do
    _battery = Keyword.fetch!(opts, :battery)

    children = [
      KubeServices.Keycloak.ClientManager,
      KubeServices.Keycloak.UserManager,
      KubeServices.Keycloak.Wrangler
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
