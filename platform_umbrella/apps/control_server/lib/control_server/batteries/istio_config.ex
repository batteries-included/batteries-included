defmodule ControlServer.Batteries.IstioConfig do
  use TypedEctoSchema
  import Ecto.Changeset

  alias KubeExt.Defaults.Images

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :namespace, :string, default: KubeExt.Defaults.Namespaces.istio()
    field :pilot_image, :string, default: Images.istio_pilot_image()
  end

  def changeset(struct, params \\ %{}) do
    cast(struct, params, [:namespace, :pilot_image])
  end
end
