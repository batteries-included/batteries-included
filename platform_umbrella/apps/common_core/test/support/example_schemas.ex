defmodule CommonCore.ExampleSchemas do
  @moduledoc false

  defmodule EmbeddedMetaSchema do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :name, :string, default: "myname"
      field :age, :integer, default: 100

      secret_field :password
    end

    def changeset(struct, attrs, opts \\ []) do
      struct
      |> CommonCore.Ecto.Schema.schema_changeset(attrs, opts)
      |> validate_exclusion(:name, ["admin"])
    end
  end

  defmodule TodoSchema do
    @moduledoc false
    use CommonCore, :schema

    @read_only_fields ~w(name)a

    batt_schema "todos" do
      slug_field :name
      defaultable_field :message, :string, default: "default message"
      secret_field :password
      secret_field :short_password, length: 8

      defaultable_image_field :image,
        default_name: "mycontainer",
        default_tag: "latest"

      defaultable_image_field :image_from_registry, image_id: :__schema_test

      embeds_one :meta, EmbeddedMetaSchema
    end
  end
end
