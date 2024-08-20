defmodule CommonCore.Actions.Grafana do
  @moduledoc false

  use CommonCore.Actions.SSOClient, client_name: "grafana"

  alias CommonCore.StateSummary.URLs

  @impl ClientConfigurator
  def configure(battery, state, client) do
    uris = URLs.uris_for_battery(state, battery.type)

    opts = [
      redirectUris: Enum.map(uris, &URLs.append_path_to_string(&1, "/login/generic_oauth")),
      webOrigins: Enum.map(uris, &URI.to_string/1)
    ]

    {struct!(client, opts), Keyword.keys(opts)}
  end
end
