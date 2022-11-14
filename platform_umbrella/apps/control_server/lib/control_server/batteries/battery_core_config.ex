defmodule ControlServer.Batteries.BatteryCoreConfig do
  use TypedEctoSchema
  import Ecto.Changeset

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :namespace, :string, default: KubeExt.Defaults.Namespaces.core()
  end

  def changeset(struct, params \\ %{}) do
    cast(struct, params, [:namespace])
  end
end
