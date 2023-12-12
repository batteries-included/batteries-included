defmodule CommonCore.Batteries.KubeMonitoringConfig do
  @moduledoc false
  use CommonCore.Util.PolymorphicType, type: :kube_monitoring
  use CommonCore.Util.DefaultableField
  use TypedEctoSchema

  alias CommonCore.Defaults

  @required_fields ~w()a

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    defaultable_field :kube_state_metrics_image, :string, default: Defaults.Images.kube_state_metrics_image()
    defaultable_field :node_exporter_image, :string, default: Defaults.Images.node_exporter_image()
    defaultable_field :metrics_server_image, :string, default: Defaults.Images.metrics_server_image()
    defaultable_field :addon_resizer_image, :string, default: Defaults.Images.addon_resizer_image()
    type_field()
  end
end
