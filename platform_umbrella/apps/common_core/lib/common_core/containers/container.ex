defmodule CommonCore.Containers.Container do
  @moduledoc false
  use CommonCore, :embedded_schema

  @required_fields ~w(image name)a

  batt_embedded_schema do
    field :path, :string, virtual: true
    field :args, {:array, :string}, default: nil

    # Should never be set directly, it gets constructed using path and args
    field :command, {:array, :string}, default: nil

    # TODO: validate that we can reach whatever registry/image/version is set
    #       in :image; at least warn if we can't
    field :image, :string
    field :name, :string

    embeds_many(:env_values, CommonCore.Containers.EnvValue, on_replace: :delete)
    embeds_many(:mounts, CommonCore.Containers.Mount, on_replace: :delete)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> CommonCore.Ecto.Schema.schema_changeset(params)
    |> downcase_fields([:name])
    |> put_command_from_path()
  end

  defp put_command_from_path(%{changes: %{path: path}} = changeset) do
    put_change(changeset, :command, [path])
  end

  defp put_command_from_path(changeset) do
    path =
      changeset
      |> get_field(:command)
      |> Kernel.||([])
      |> List.first()

    put_change(changeset, :path, path)
  end
end
