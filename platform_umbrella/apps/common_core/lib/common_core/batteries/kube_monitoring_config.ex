defmodule CommonCore.Batteries.KubeMonitoringConfig do
  @moduledoc false
  use TypedEctoSchema

  import Ecto.Changeset

  alias CommonCore.Defaults

  @optional_fields [
    :kube_state_metrics_image,
    :node_exporter_image
  ]
  @required_fields []

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :kube_state_metrics_image, :string, default: Defaults.Images.kube_state_metrics_image()
    field :node_exporter_image, :string, default: Defaults.Images.node_exporter_image()
    field :metrics_server_image, :string, default: Defaults.Images.metrics_server_image()
    field :addon_resizer_image, :string, default: Defaults.Images.addon_resizer_image()
  end

  def changeset(struct, params \\ %{}) do
    cast(struct, params, @optional_fields ++ @required_fields)
  end
end
