defmodule CommonCore.Defaults.Image do
  @moduledoc false
  use CommonCore, :embedded_schema

  @required_fields ~w(name tags default_tag)a

  batt_embedded_schema do
    field :name, :string
    field :tags, {:array, :string}
    field :default_tag, :string
  end

  @doc false
  def changeset(image, attrs, opts \\ []) do
    image
    |> CommonCore.Ecto.Schema.schema_changeset(attrs, opts)
    |> default_tag_in_tags()
  end

  def default_tag_in_tags(changeset) do
    changeset
    |> Ecto.Changeset.get_field(:tags, [])
    |> Kernel.||([])
    |> then(&Ecto.Changeset.validate_inclusion(changeset, :default_tag, &1))
  end
end
