defmodule CommonCore.Batteries.KialiConfig do
  use TypedEctoSchema
  import Ecto.Changeset

  alias CommonCore.Defaults

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :operator_image, :string, default: Defaults.Images.kiali_operator_image()
    field :version, :string, default: Defaults.Monitoring.kiali_version()
  end

  def changeset(struct, params \\ %{}) do
    cast(struct, params, [:operator_image, :version])
  end
end
