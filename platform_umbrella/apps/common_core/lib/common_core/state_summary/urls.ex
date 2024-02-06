defmodule CommonCore.StateSummary.URLs do
  @moduledoc false

  alias CommonCore.StateSummary
  alias CommonCore.StateSummary.Batteries
  alias CommonCore.StateSummary.Hosts

  @spec uri_for_battery(StateSummary.t(), atom()) :: URI.t()
  def uri_for_battery(state, battery) do
    "http://#{Hosts.for_battery(state, battery)}"
    |> URI.new!()
    |> then(fn uri ->
      if Batteries.batteries_installed?(state, :cert_manager), do: %URI{uri | scheme: "https", port: 443}, else: uri
    end)
  end

  @spec keycloak_uri_for_realm(StateSummary.t(), String.t()) :: URI.t()
  def keycloak_uri_for_realm(state, realm) do
    state
    |> uri_for_battery(:keycloak)
    |> URI.append_path("/realms/#{realm}")
  end
end
