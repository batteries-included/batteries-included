defmodule CommonCore.Actions.Notebooks do
  @moduledoc false

  use CommonCore.Actions.SSOClient, client_name: "notebooks"

  @impl ClientConfigurator
  def configure(_battery, _state, client), do: {client, []}
end
