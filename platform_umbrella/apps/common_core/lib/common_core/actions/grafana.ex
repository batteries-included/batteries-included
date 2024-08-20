defmodule CommonCore.Actions.Grafana do
  @moduledoc false

  use CommonCore.Actions.SSOClient, client_name: "grafana"

  alias CommonCore.StateSummary.URLs

  @impl ClientConfigurator
  def configure(battery, state, client) do
    redirect_uris =
      state
      |> URLs.uris_for_battery(battery.type)
      |> Enum.map(&URLs.append_path_to_string(&1, "/login/generic_oauth"))

    opts = [redirectUris: redirect_uris]
    {struct!(client, opts), Keyword.keys(opts)}
  end
end
