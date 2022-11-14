defmodule ControlServer.Batteries.MetalLBConfig do
  use TypedEctoSchema
  import Ecto.Changeset

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :namespace, :string, default: KubeExt.Defaults.Namespaces.loadbalancer()
  end

  def changeset(struct, params \\ %{}) do
    cast(struct, params, [:namespace])
  end
end
