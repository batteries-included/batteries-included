defmodule CommonCore.Batteries.ControlServerConfig do
  use TypedEctoSchema
  import Ecto.Changeset

  alias CommonCore.Defaults
  alias CommonCore.Defaults.RandomKeyChangeset

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :image, :string, default: Defaults.Images.control_server_image()
    field :secret_key, :string
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:image, :secret_key])
    |> RandomKeyChangeset.maybe_set_random(:secret_key)
  end
end
