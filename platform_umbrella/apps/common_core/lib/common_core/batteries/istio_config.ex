defmodule CommonCore.Batteries.IstioConfig do
  @moduledoc false
  use TypedEctoSchema

  import Ecto.Changeset

  alias CommonCore.Defaults

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :namespace, :string, default: Defaults.Namespaces.istio()
    field :pilot_image, :string, default: Defaults.Images.istio_pilot_image()
  end

  def changeset(struct, params \\ %{}) do
    cast(struct, params, [:namespace, :pilot_image])
  end
end
