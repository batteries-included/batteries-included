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

    def changeset(struct, attrs) do
      struct
      |> CommonCore.Ecto.Schema.schema_changeset(attrs)
      |> validate_exclusion(:name, ["admin"])
    end
  end

  defmodule TodoSchema do
    @moduledoc false
    use CommonCore, :schema

    batt_schema "todos" do
      field :name, :string
      defaultable_field :image, :string, default: "mycontainer:latest"
      secret_field :password
      secret_field :short_password, length: 8

      embeds_one :meta, EmbeddedMetaSchema
    end
  end
end
