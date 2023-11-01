defmodule CommonCore.Actions.Gitea do
  @moduledoc false

  use CommonCore.Actions.SSOClient, client_name: "gitea"

  @impl ClientConfigurator
  def configure(_battery, _state, client), do: {client, []}
end
