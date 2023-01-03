defmodule CommonCore.Batteries.MLCoreConfig do
  use TypedEctoSchema
  import Ecto.Changeset

  alias CommonCore.Defaults

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :namespace, :string, default: Defaults.Namespaces.data()
  end

  def changeset(struct, params \\ %{}) do
    cast(struct, params, [:namespace])
  end
end
