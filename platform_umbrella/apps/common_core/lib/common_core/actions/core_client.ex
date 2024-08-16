defmodule CommonCore.Actions.CoreClient do
  @moduledoc false
  use CommonCore.Actions.SSOClient, client_name: "battery_core"

  alias CommonCore.StateSummary.URLs

  @impl ClientConfigurator
  def configure(battery, state, client) do
    redirect_uris =
      state
      |> URLs.uris_for_battery(battery.type)
      |> Enum.map(&URLs.append_path_to_string(&1, "/sso/callback*"))

    opts = [redirectUris: redirect_uris]
    {struct!(client, opts), Keyword.keys(opts)}
  end
end
