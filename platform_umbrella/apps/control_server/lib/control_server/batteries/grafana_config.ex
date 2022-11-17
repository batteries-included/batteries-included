defmodule ControlServer.Batteries.GrafanaConfig do
  use TypedEctoSchema
  import Ecto.Changeset

  alias KubeExt.Defaults

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field(:image, :string, default: Defaults.Images.grafana_image())
    field(:sidecar_image, :string, default: Defaults.Images.kiwigrid_sidecar_image())
  end

  def changeset(struct, params \\ %{}) do
    cast(struct, params, [:image, :sidecar_image])
  end
end
