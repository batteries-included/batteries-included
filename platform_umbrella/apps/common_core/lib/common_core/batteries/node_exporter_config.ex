defmodule CommonCore.Batteries.NodeExporterConfig do
  use TypedEctoSchema
  import Ecto.Changeset

  alias CommonCore.Defaults

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :image, :string, default: Defaults.Images.node_exporter_image()
  end

  def changeset(struct, params \\ %{}) do
    cast(struct, params, [:image])
  end
end
