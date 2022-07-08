defmodule KubeResources.SecuritySettings do
  @moduledoc """
  Module around turning BaseService json config into usable settings.
  """
  import KubeExt.MapSettings

  @namespace "battery-core"
  @metrics_spi_version "2.5.3"
  @keycloak_operator_image "quay.io/keycloak/keycloak-operator:18.0.2"

  setting(:namespace, :namespace, @namespace)
  setting(:keycloak_operator_image, :image, @keycloak_operator_image)
  setting(:keycloak_metrics_spi_version, :metrics_spi_version, @metrics_spi_version)
end
