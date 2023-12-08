defmodule CommonCore.Util.PolymorphicTypeTest do
  @moduledoc false
  use ExUnit.Case

  import Ecto.Changeset

  alias CommonCore.Util.PolymorphicType
  alias CommonCore.Util.PolymorphicTypeTest

  @mappings [
    advanced: PolymorphicTypeTest.AdvancedConfig,
    basic: PolymorphicTypeTest.BasicConfig
  ]

  defmodule BasicConfig do
    @moduledoc false
    use CommonCore.Util.PolymorphicType, type: :basic
    use TypedEctoSchema

    @primary_key false
    typed_embedded_schema do
      field :non_default, :string
      type_field()
    end
  end

  defmodule AdvancedConfig do
    @moduledoc false
    use CommonCore.Util.PolymorphicType, type: :advanced
    use CommonCore.Util.DefaultableField
    use TypedEctoSchema

    @required_fields ~w(non_default)a
    @primary_key false
    typed_embedded_schema do
      field :non_default, :string
      defaultable_field :defaulted, :string, default: "some default value"
      type_field()
    end
  end

  defmodule TypeWithConfig do
    @moduledoc false
    use TypedEctoSchema

    import Ecto.Changeset

    alias CommonCore.Util.PolymorphicType

    @primary_key {:id, :binary_id, autogenerate: true}
    typed_schema "test_type" do
      field :config, PolymorphicType,
        mappings: [
          advanced: PolymorphicTypeTest.AdvancedConfig,
          basic: PolymorphicTypeTest.BasicConfig
        ]

      timestamps()
    end

    def changeset(struct, attrs) do
      struct
      |> cast(attrs, [:config])
      |> validate_required([:config])
    end
  end

  test "can create valid changeset" do
    assert %Ecto.Changeset{errors: [], valid?: true, changes: %{config: config}} =
             TypeWithConfig.changeset(%TypeWithConfig{}, %{config: %AdvancedConfig{non_default: "something"}})

    assert %AdvancedConfig{
             non_default: "something",
             defaulted: "some default value",
             defaulted_override: nil,
             type: :advanced
           } = config
  end

  test "can create invalid changeset" do
    assert %Ecto.Changeset{errors: [config: {"is invalid", _}], valid?: false} =
             TypeWithConfig.changeset(%TypeWithConfig{}, %{config: %AdvancedConfig{}})
  end

  test "can override default field in config" do
    assert %Ecto.Changeset{errors: [], valid?: true, changes: %{config: config}} =
             TypeWithConfig.changeset(%TypeWithConfig{}, %{config: advanced_config(:struct, :all)})

    assert %AdvancedConfig{
             non_default: "set",
             defaulted: "overridden!",
             defaulted_override: "overridden!",
             type: :advanced
           } =
             config
  end

  test "can dump configs" do
    assert {:ok, %{non_default: "set", type: :advanced, defaulted_override: nil}} =
             Ecto.Type.dump(AdvancedConfig, advanced_config(:struct, :empty))

    assert {:ok, %{non_default: "set", type: :advanced, defaulted_override: "overridden!"}} =
             Ecto.Type.dump(AdvancedConfig, advanced_config(:struct, :all))

    assert {:ok, %{type: :basic, non_default: nil}} = Ecto.Type.dump(BasicConfig, basic_config(:struct, :empty))
    assert {:ok, %{type: :basic, non_default: "set"}} = Ecto.Type.dump(BasicConfig, basic_config(:struct, :all))
  end

  test "init/1: fails if missing mappings" do
    assert_raise RuntimeError, fn -> PolymorphicType.init([]) end
  end

  test "init/1: converts opts to map" do
    assert %{} = PolymorphicType.init(mappings: [])
  end

  test "cast/2: handles nil value" do
    assert {:ok, nil} = PolymorphicType.cast(nil, %{mappings: @mappings, field: :config})
  end

  test "cast/2: handles map value with type set" do
    params = %{mappings: @mappings, field: :config}
    assert {:ok, %AdvancedConfig{type: :advanced}} = PolymorphicType.cast(advanced_config(:map, :empty), params)

    assert {:ok,
            %AdvancedConfig{
              non_default: "set",
              defaulted: "overridden!",
              defaulted_override: "overridden!",
              type: :advanced
            }} =
             PolymorphicType.cast(advanced_config(:map, :all), params)

    assert {:ok, %BasicConfig{type: :basic}} = PolymorphicType.cast(basic_config(:map, :empty), params)
    assert {:ok, %BasicConfig{type: :basic, non_default: nil}} = PolymorphicType.cast(basic_config(:map, :empty), params)

    assert {:ok, %BasicConfig{type: :basic, non_default: "set"}} =
             PolymorphicType.cast(basic_config(:map, :all), params)
  end

  test "cast/2: handles struct value" do
    params = %{mappings: @mappings, field: :config}
    assert {:ok, %AdvancedConfig{type: :advanced}} = PolymorphicType.cast(advanced_config(:struct, :empty), params)

    assert {:ok,
            %AdvancedConfig{
              non_default: "set",
              defaulted: "overridden!",
              defaulted_override: "overridden!",
              type: :advanced
            }} =
             PolymorphicType.cast(advanced_config(:struct, :all), params)

    assert {:ok, %BasicConfig{type: :basic}} = PolymorphicType.cast(basic_config(:struct, :empty), params)

    assert {:ok, %BasicConfig{type: :basic, non_default: nil}} =
             PolymorphicType.cast(basic_config(:struct, :empty), params)
  end

  test "cast/2: handles required fields" do
    assert :error = PolymorphicType.cast(%AdvancedConfig{}, %{mappings: @mappings, field: :config})
  end

  test "cast/2: handles unmapped data gracefully" do
    params = %{mappings: [], field: :config}
    # for structs we don't need the mapping as we can just delegate to the module of the struct
    assert {:ok, %BasicConfig{non_default: nil, type: :basic}} =
             PolymorphicType.cast(basic_config(:struct, :empty), params)

    # maps need mapping so we know which `cast` to call
    assert {:error, [config: "no matching type in mappings"]} = PolymorphicType.cast(basic_config(:map, :all), params)
  end

  test "cast/2: handles stringly keyed data" do
    assert {:ok, %CommonCore.Util.PolymorphicTypeTest.BasicConfig{non_default: "set", type: :basic}} =
             PolymorphicType.cast(basic_config(:map, :stringly), %{mappings: @mappings, field: :config})
  end

  test "dump/3: handles nil value" do
    assert {:ok, nil} = PolymorphicType.dump(nil, &Function.identity/1, %{mappings: @mappings})
  end

  test "dump/3: handles overrides" do
    expected = %{defaulted_override: "overridden!", non_default: "set", type: :advanced}

    out = PolymorphicType.dump(advanced_config(:struct, :all), &Function.identity/1, %{mappings: @mappings})
    assert {:ok, ^expected} = out
    refute Map.has_key?(elem(out, 1), :defaulted)
  end

  test "load/3: handles nil" do
    assert {:ok, nil} = PolymorphicType.load(nil, &Function.identity/1, %{mappings: @mappings})
  end

  test "load/3: handles stringly keyed maps" do
    assert {:ok, %BasicConfig{non_default: "set", type: :basic}} =
             PolymorphicType.load(basic_config(:map, :stringly), &Function.identity/1, %{mappings: @mappings})
  end

  test "load/3: handles unsets and defaults" do
    expected = %AdvancedConfig{non_default: "set", defaulted: "some default value", type: :advanced}

    assert {:ok, ^expected} =
             PolymorphicType.load(advanced_config(:map, :empty), &Function.identity/1, %{mappings: @mappings})
  end

  test "load/3: handles overrides" do
    expected = %AdvancedConfig{
      defaulted: "overridden!",
      defaulted_override: "overridden!",
      non_default: "set",
      type: :advanced
    }

    assert {:ok, ^expected} =
             PolymorphicType.load(advanced_config(:map, :stringly), &Function.identity/1, %{mappings: @mappings})
  end

  test "load/3: handles unmapped data gracefully" do
    assert :error = PolymorphicType.load(basic_config(:map, :empty), &Function.identity/1, %{mappings: []})
    assert :error = PolymorphicType.load(basic_config(:map, :stringly), &Function.identity/1, %{mappings: []})
    assert :error = PolymorphicType.load(advanced_config(:map, :empty), &Function.identity/1, %{mappings: []})
    assert :error = PolymorphicType.load(advanced_config(:map, :stringly), &Function.identity/1, %{mappings: []})
  end

  defp basic_config(format, preset)
  defp basic_config(:struct, :empty), do: %BasicConfig{}
  defp basic_config(:struct, :all), do: %BasicConfig{non_default: "set"}
  defp basic_config(:map, :stringly), do: %{"non_default" => "set", "type" => :basic}
  defp basic_config(:map, preset), do: Map.from_struct(basic_config(:struct, preset))

  defp advanced_config(format, preset)
  defp advanced_config(:struct, :empty), do: %AdvancedConfig{non_default: "set"}
  defp advanced_config(:struct, :all), do: %AdvancedConfig{non_default: "set", defaulted_override: "overridden!"}

  defp advanced_config(:map, :stringly),
    do: %{"non_default" => "set", "defaulted_override" => "overridden!", "type" => :advanced}

  defp advanced_config(:map, preset), do: Map.from_struct(advanced_config(:struct, preset))
end
