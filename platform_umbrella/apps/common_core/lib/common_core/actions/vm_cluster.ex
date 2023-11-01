defmodule CommonCore.Actions.VMCluster do
  @moduledoc false

  use CommonCore.Actions.SSOClient, client_name: "vm_cluster"

  @impl ClientConfigurator
  def configure(_battery, _state, client), do: {client, []}
end
