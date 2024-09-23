defmodule CommonCore.Containers.Container do
  @moduledoc false
  use CommonCore, :embedded_schema

  @required_fields ~w(image name)a

  batt_embedded_schema do
    field :args, {:array, :string}, default: nil
    field :command, {:array, :string}, default: nil

    # TODO: validate that we can reach whatever registry/image/version is set
    #       in :image; at least warn if we can't
    field :image, :string
    field :name, :string

    embeds_many(:env_values, CommonCore.Containers.EnvValue, on_replace: :delete)
    embeds_many(:mounts, CommonCore.Containers.Mount, on_replace: :delete)
  end

  def changeset(struct, params \\ %{}, opts \\ []) do
    struct
    |> CommonCore.Ecto.Schema.schema_changeset(params, opts)
    |> downcase_fields([:name])
  end
end
