defmodule KubeRawResources.ConfigGenerator do
  alias KubeRawResources.Battery
  alias KubeRawResources.ControlServerResources
  alias KubeRawResources.Database
  alias KubeRawResources.IstioBase
  alias KubeRawResources.IstioIstiod
  alias KubeRawResources.PostgresOperator

  def materialize(:postgres_operator), do: PostgresOperator.materialize(%{})

  def materialize(:database_internal),
    do: Database.materialize(%{"bootstrap_clusters" => [Battery.control_cluster()]})

  def materialize(:battery_core), do: Battery.materialize(%{})
  def materialize(:control_server), do: ControlServerResources.materialize(%{})
  def materialize(:istio), do: IstioBase.materialize(%{})
  def materialize(:istio_istiod), do: IstioIstiod.materialize(%{})
end
