defmodule KubeServices.Batteries.Keycloak do
  @moduledoc false
  use KubeServices.Batteries.Supervisor

  require Logger

  def init(opts) do
    _battery = Keyword.fetch!(opts, :battery)

    children = [
      KubeServices.Keycloak.Wrangler,
      KubeServices.Keycloak.UserManager
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
