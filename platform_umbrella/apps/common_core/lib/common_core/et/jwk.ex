defmodule CommonCore.ET.JWK do
  @moduledoc false

  import CommonCore.StateSummary.Core, only: [config_field: 2]

  alias CommonCore.Batteries.BatteryCoreConfig

  def jwk(%BatteryCoreConfig{} = config) do
    dbg("JWK: #{config.control_jwk}")
    dbg(config.control_jwk)
  end

  def jwk(summary) do
    summary
    |> config_field(:control_jwk)
    |> JOSE.JWK.from_map()
  end
end
