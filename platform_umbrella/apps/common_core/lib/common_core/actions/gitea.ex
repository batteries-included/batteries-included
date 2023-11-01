defmodule CommonCore.Actions.Gitea do
  @moduledoc false

  use CommonCore.Actions.SSOClient, client_name: "gitea"

  @impl Client
  def configure_client(_battery, _state, client), do: {client, []}
end
