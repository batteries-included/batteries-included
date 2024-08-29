defmodule CommonCore.Batteries.KubeMonitoringConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  batt_polymorphic_schema type: :kube_monitoring do
    defaultable_image_field :kube_state_metrics_image, image_id: :kube_state_metrics
    defaultable_image_field :node_exporter_image, image_id: :node_exporter
    defaultable_image_field :metrics_server_image, image_id: :metrics_server
    defaultable_image_field :addon_resizer_image, image_id: :addon_resizer
  end
end
