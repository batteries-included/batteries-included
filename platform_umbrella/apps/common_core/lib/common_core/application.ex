defmodule CommonCore.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    # Make sure JOSE is using the fast curve25519 implementation
    :ok = JOSE.curve25519_module(:libdecaf)

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
