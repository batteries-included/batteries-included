defmodule KubeResources.SecuritySettings do
  @moduledoc """
  Module around turning BaseService json config into usable settings.
  """
  @namespace "battery-core"
  @metrics_spi_version "2.5.3"

  @spec namespace(map()) :: binary()
  def namespace(config), do: Map.get(config, "namespace", @namespace)

  @spec keycloak_metrics_version(map) :: binary()
  def keycloak_metrics_version(config),
    do: Map.get(config, "keycloak.metrics_spi_version", @metrics_spi_version)
end
