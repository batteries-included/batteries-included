defmodule KubeResources.DatabaseSettings do
  @moduledoc """
  Module for extracting the setting from a map usually a json map from the BaseService ecto
  """
  @namepace "battery-core"

  @pg_operator_name "battery-pg-operator"
  @pg_operator_pod_account_name "battery-pg-pod"
  @pg_operator_image "registry.opensource.zalan.do/acid/postgres-operator"
  @pg_operator_version "v1.6.3"

  def namespace(config), do: Map.get(config, "namespace", @namepace)
  def pg_operator_name(config), do: Map.get(config, "pg_operator.name", @pg_operator_name)

  def pg_operator_pod_account_name(config),
    do: Map.get(config, "pg_operator.pod_account_name", @pg_operator_pod_account_name)

  def pg_operator_image(config), do: Map.get(config, "pg_operator.image", @pg_operator_image)

  def pg_operator_version(config),
    do: Map.get(config, "pg_operator.version", @pg_operator_version)
end
