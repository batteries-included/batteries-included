defmodule ControlServer.Batteries.PrometheusOperatorConfig do
  use TypedEctoSchema
  import Ecto.Changeset

  alias KubeExt.Defaults

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field(:image, :string, default: Defaults.Images.prometheus_operator_image())
    field(:reloader_image, :string, default: Defaults.Images.prometheus_reloader_image())
    field(:kubelet_service, :string, default: Defaults.Monitoring.kubelet_service())
  end

  def changeset(struct, params \\ %{}) do
    cast(struct, params, [:image, :reloader_image, :kubelet_service])
  end
end
