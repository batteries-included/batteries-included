defmodule CommonCore.Knative.Container do
  @moduledoc false
  use TypedEctoSchema

  import CommonCore.Util.EctoValidations
  import Ecto.Changeset

  @required_fields ~w(image name)a
  @optional_fields ~w(args command)a

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :args, {:array, :string}, default: nil
    field :command, {:array, :string}, default: nil

    # TODO: validate that we can reach whatever registry/image/version is set
    #       in :image; at least warn if we can't
    field :image, :string
    field :name, :string

    embeds_many(:env_values, CommonCore.Knative.EnvValue, on_replace: :delete)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, Enum.concat(@required_fields, @optional_fields))
    |> validate_required(@required_fields)
    |> cast_embed(:env_values)
    |> downcase_fields([:name])
  end
end
