defmodule CommonCore.Actions.Smtp4dev do
  @moduledoc false

  use CommonCore.Actions.SSOClient, client_name: "smtp4dev"

  @impl Client
  def configure_client(_battery, _state, client) do
    opts = [adminUrl: nil, baseUrl: nil, redirectUris: ["/*"], webOrigins: nil]
    {struct!(client, opts), Keyword.keys(opts)}
  end
end
