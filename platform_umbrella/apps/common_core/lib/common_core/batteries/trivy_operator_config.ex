defmodule CommonCore.Batteries.TrivyOperatorConfig do
  @moduledoc false
  use TypedEctoSchema

  import Ecto.Changeset

  alias CommonCore.Defaults

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :image, :string, default: Defaults.Images.trivy_operator_image()
    field :version_tag, :string, default: "0.42.0"
  end

  def changeset(struct, params \\ %{}) do
    cast(struct, params, [:image, :version_tag])
  end
end
