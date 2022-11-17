defmodule ControlServer.Batteries.MetalLBIPPoolConfig do
  use TypedEctoSchema

  import Ecto.Changeset

  alias KubeExt.Defaults

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field(:pools, {:array, :string}, default: Defaults.Network.metallb_ip_pools())
  end

  def changeset(struct, params \\ %{}) do
    cast(struct, params, [:pools])
  end
end
