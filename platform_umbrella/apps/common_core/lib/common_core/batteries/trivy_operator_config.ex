defmodule CommonCore.Batteries.TrivyOperatorConfig do
  use TypedEctoSchema
  import Ecto.Changeset

  alias CommonCore.Defaults

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :image, :string, default: Defaults.Images.trivy_operator_image()
    field :version_tag, :string, default: "0.37.2"
  end

  def changeset(struct, params \\ %{}) do
    cast(struct, params, [:image, :version_tag])
  end
end
