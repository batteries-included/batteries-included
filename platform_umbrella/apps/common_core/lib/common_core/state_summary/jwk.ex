defmodule CommonCore.StateSummary.JWK do
  @moduledoc false

  import CommonCore.StateSummary.Core, only: [config_field: 2]

  def jwk(summary) do
    summary
    |> config_field(:control_jwk)
    |> JOSE.JWK.from_map()
  end
end
