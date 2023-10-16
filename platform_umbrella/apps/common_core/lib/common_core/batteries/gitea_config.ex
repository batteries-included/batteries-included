defmodule CommonCore.Batteries.GiteaConfig do
  @moduledoc false
  use TypedEctoSchema

  import Ecto.Changeset

  alias CommonCore.Defaults
  alias CommonCore.Defaults.RandomKeyChangeset

  @required_fields ~w()a
  @optional_fields ~w(image admin_username admin_password)a

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :image, :string, default: Defaults.Images.gitea_image()
    field :admin_username, :string, default: "battery-gitea-admin"
    field :admin_password, :string
  end

  def changeset(struct, params \\ %{}) do
    fields = Enum.concat(@required_fields, @optional_fields)

    struct
    |> cast(params, fields)
    |> RandomKeyChangeset.maybe_set_random(:admin_password)
    |> validate_required(@required_fields)
  end
end
