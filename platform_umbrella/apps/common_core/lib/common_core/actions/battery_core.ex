defmodule CommonCore.Actions.BatteryCore do
  @moduledoc false

  use CommonCore.Actions.SSOClient, client_name: "battery_core"

  @impl ClientConfigurator
  def configure(_battery, _state, client) do
    opts = [adminUrl: nil, baseUrl: nil, redirectUris: ["*"], webOrigins: nil]
    {struct!(client, opts), Keyword.keys(opts)}
  end
end
