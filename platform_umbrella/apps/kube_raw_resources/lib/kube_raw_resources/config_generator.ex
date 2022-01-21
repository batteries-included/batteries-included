defmodule KubeRawResources.ConfigGenerator do
  alias KubeRawResources.Battery
  alias KubeRawResources.Database

  def materialize(%{} = config, :database), do: Database.materialize(config)
  def materialize(%{} = config, :battery), do: Battery.materialize(config)
  def materialize(%{}, _), do: Map.new()
end
