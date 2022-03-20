defmodule KubeRawResources.ConfigGenerator do
  alias KubeRawResources.Battery
  alias KubeRawResources.ControlServerResources
  alias KubeRawResources.Database
  alias KubeRawResources.IstioBase
  alias KubeRawResources.IstioIstiod

  def materialize(:database), do: Database.materialize_common(%{})

  def materialize(:database_internal),
    do: Database.materialize(%{"bootstrap.clusters" => [Battery.control_cluster()]})

  def materialize(:battery), do: Battery.materialize(%{})
  def materialize(:control_server), do: ControlServerResources.materialize(%{})
  def materialize(:istio), do: IstioBase.materialize(%{})
  def materialize(:istio_istiod), do: IstioIstiod.materialize(%{})
end
