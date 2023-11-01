defmodule CommonCore.Actions.Grafana do
  @moduledoc false

  use CommonCore.Actions.SSOClient, client_name: "grafana"

  @impl ClientConfigurator
  def configure(_battery, _state, client) do
    opts = [redirectUris: ["/login/generic_oauth"]]
    {struct!(client, opts), Keyword.keys(opts)}
  end
end
