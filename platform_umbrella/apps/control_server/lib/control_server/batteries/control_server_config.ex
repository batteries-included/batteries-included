defmodule ControlServer.Batteries.ControlServerConfig do
  use TypedEctoSchema
  import Ecto.Changeset

  alias KubeExt.Defaults

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :image, :string, default: Defaults.Images.control_server_image()
    field :secret_key, :string, default: "NOTREAL"
  end

  def changeset(struct, params \\ %{}) do
    cast(struct, params, [:image, :secret_key])
  end
end
