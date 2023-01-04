defmodule CommonCore.Batteries.KubeStateMetricsConfig do
  use TypedEctoSchema
  import Ecto.Changeset

  alias CommonCore.Defaults

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :image, :string, default: Defaults.Images.kube_state_metrics_image()
  end

  def changeset(struct, params \\ %{}) do
    cast(struct, params, [:image])
  end
end
