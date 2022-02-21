defmodule KubeRawResources.ConfigGenerator do
  alias KubeRawResources.Battery
  alias KubeRawResources.Database
  alias KubeRawResources.ControlServerResources

  def materialize(%{} = config, :database), do: Database.materialize(config)
  def materialize(%{} = config, :battery), do: Battery.materialize(config)
  def materialize(%{} = config, :control_server), do: ControlServerResources.materialize(config)
end
