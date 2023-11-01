defmodule CommonCore.Actions.VMAgent do
  @moduledoc false

  use CommonCore.Actions.SSOClient, client_name: "vm_agent"

  @impl ClientConfigurator
  def configure(_battery, _state, client), do: {client, []}
end
