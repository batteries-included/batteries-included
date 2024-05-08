defmodule CommonCore.Batteries.KubeMonitoringConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  alias CommonCore.Defaults

  batt_polymorphic_schema type: :kube_monitoring do
    defaultable_field :kube_state_metrics_image, :string, default: Defaults.Images.kube_state_metrics_image()
    defaultable_field :node_exporter_image, :string, default: Defaults.Images.node_exporter_image()
    defaultable_field :metrics_server_image, :string, default: Defaults.Images.metrics_server_image()
    defaultable_field :addon_resizer_image, :string, default: Defaults.Images.addon_resizer_image()
  end
end
