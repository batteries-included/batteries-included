defmodule CommonCore.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Finch worker for HTTP requests
      # used by Tesla adapter in ET and Keycloak
      {Finch, name: CommonCore.Finch},
      # Cache for JWKs
      CommonCore.JWK.Cache
    ]

    opts = [strategy: :one_for_one, name: CommonCore.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
