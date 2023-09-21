defmodule CommonCore.Defaults.Keycloak do
  @moduledoc false

  # Keycloak requires us to use the name for most things.
  #
  # So well pick one for core assuming that there will be expansions ?
  def realm_name, do: "batterycore"
end
