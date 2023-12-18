defmodule CommonCore.Actions.Smtp4dev do
  @moduledoc false

  use CommonCore.Actions.SSOClient, client_name: "smtp4dev"

  @impl ClientConfigurator
  def configure(_battery, _state, client) do
    opts = [baseUrl: nil, redirectUris: ["/*"], webOrigins: []]
    {struct!(client, opts), Keyword.keys(opts)}
  end
end
