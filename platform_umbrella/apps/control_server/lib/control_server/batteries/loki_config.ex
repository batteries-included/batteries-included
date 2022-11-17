defmodule ControlServer.Batteries.LokiConfig do
  use TypedEctoSchema
  import Ecto.Changeset

  alias KubeExt.Defaults

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field(:image, :string, default: Defaults.Images.loki_image())
    field(:agent_operator_image, :string, default: Defaults.Images.grafana_agent_operator_image())
  end

  def changeset(struct, params \\ %{}) do
    cast(struct, params, [:image, :agent_operator_image])
  end
end
