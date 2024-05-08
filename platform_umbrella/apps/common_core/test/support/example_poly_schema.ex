defmodule CommonCore.ExamplePolySchema do
  @moduledoc false

  defmodule FooPayloadSchema do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_polymorphic_schema type: :foo do
      field :setting_a, :string, default: "FooValueA"
      field :setting_b, :string, default: "FooValueB"
    end
  end

  defmodule BarPayloadSchema do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_polymorphic_schema type: :bar do
      field :setting_a, :string, default: "BarValueA"
      field :setting_c, :string, default: "BarValueC"
    end
  end

  defmodule RootSchema do
    @moduledoc false
    use CommonCore, :schema

    batt_schema "roots" do
      field :name, :string, default: "myname"

      field :payload, CommonCore.Ecto.PolymorphicType,
        mappings: %{
          foo: FooPayloadSchema,
          bar: BarPayloadSchema
        }

      timestamps()
    end
  end
end
