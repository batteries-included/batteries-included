defmodule KubeRawResources.ConfigGenerator do
  alias KubeRawResources.Battery
  alias KubeRawResources.ControlServerResources
  alias KubeRawResources.Database
  alias KubeRawResources.Istio

  def materialize(:database), do: Database.materialize_common(%{})

  def materialize(:database_internal),
    do: Database.materialize(%{"bootstrap.clusters" => [Battery.control_cluster()]})

  def materialize(:istio), do: Istio.materialize(%{})
  def materialize(:battery), do: Battery.materialize(%{})
  def materialize(:control_server), do: ControlServerResources.materialize(%{})
end
