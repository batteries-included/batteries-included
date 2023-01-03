defmodule CommonCore.Batteries.BatteryCoreConfig do
  use TypedEctoSchema
  import Ecto.Changeset

  alias CommonCore.Defaults

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :core_namespace, :string, default: Defaults.Namespaces.core()
    field :base_namespace, :string, default: Defaults.Namespaces.base()
  end

  def changeset(struct, params \\ %{}) do
    cast(struct, params, [:core_namespace, :base_namespace])
  end
end
