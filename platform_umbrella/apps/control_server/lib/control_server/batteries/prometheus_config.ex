defmodule ControlServer.Batteries.PrometheusConfig do
  use TypedEctoSchema
  import Ecto.Changeset

  alias KubeExt.Defaults

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field(:image, :string, default: Defaults.Images.prometheus_image())
    field(:version, :string, default: Defaults.Monitoring.prometheus_version())
    field(:retention, :string, default: Defaults.Monitoring.prometheus_retention())
  end

  def changeset(struct, params \\ %{}) do
    cast(struct, params, [:image, :version, :retention])
  end
end
