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
      field :type, Ecto.Enum, values: [:basic], default: :basic
    end
  end

  defmodule AdvancedConfig do
    @moduledoc false
    use CommonCore.Util.PolymorphicType, type: :advanced
    use CommonCore.Util.DefaultableField
    use TypedEctoSchema

    @primary_key false
    typed_embedded_schema do
      field :non_default, :string
      defaultable_field :defaulted, :string, default: "some default value"
      field :type, Ecto.Enum, values: [:advanced], default: :advanced
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

  test "can create changeset" do
    assert %Ecto.Changeset{errors: [], valid?: true, changes: %{config: config}} =
             TypeWithConfig.changeset(%TypeWithConfig{}, %{config: %AdvancedConfig{}})

    assert %AdvancedConfig{non_default: nil, defaulted: nil, defaulted_override: nil, type: :advanced} = config
  end

  test "can override default field in config" do
    assert %Ecto.Changeset{errors: [], valid?: true, changes: %{config: config}} =
             TypeWithConfig.changeset(%TypeWithConfig{}, %{config: %AdvancedConfig{defaulted_override: "not the default"}})

    assert %AdvancedConfig{non_default: nil, defaulted: nil, defaulted_override: "not the default", type: :advanced} =
             config
  end

  test "init/1: fails if missing mappings" do
    assert_raise RuntimeError, fn -> PolymorphicType.init([]) end
  end

  test "init/1: converts opts to map" do
    assert %{} = PolymorphicType.init(mappings: [])
  end

  test "cast/2: handles nil value" do
    assert {:ok, nil} = PolymorphicType.cast(nil, %{mappings: @mappings})
  end

  test "cast/2: handles map value with type set" do
    assert {:ok, %AdvancedConfig{type: :advanced}} =
             PolymorphicType.cast(advanced_config(:map, :empty), %{mappings: @mappings})

    assert {:ok, %AdvancedConfig{non_default: "set", defaulted: nil, defaulted_override: "overridden!", type: :advanced}} =
             PolymorphicType.cast(advanced_config(:map, :all), %{mappings: @mappings})

    assert {:ok, %BasicConfig{type: :basic}} = PolymorphicType.cast(basic_config(:map, :empty), %{mappings: @mappings})

    assert {:ok, %BasicConfig{type: :basic, non_default: nil}} =
             PolymorphicType.cast(basic_config(:map, :empty), %{mappings: @mappings})
  end

  test "cast/2: handles struct value" do
    assert {:ok, %AdvancedConfig{type: :advanced}} =
             PolymorphicType.cast(advanced_config(:struct, :empty), %{mappings: @mappings})

    assert {:ok, %AdvancedConfig{non_default: "set", defaulted: nil, defaulted_override: "overridden!", type: :advanced}} =
             PolymorphicType.cast(advanced_config(:struct, :all), %{mappings: @mappings})

    assert {:ok, %BasicConfig{type: :basic}} =
             PolymorphicType.cast(basic_config(:struct, :empty), %{mappings: @mappings})

    assert {:ok, %BasicConfig{type: :basic, non_default: nil}} =
             PolymorphicType.cast(basic_config(:struct, :empty), %{mappings: @mappings})
  end

  test "dump/3: handles nil value" do
    assert {:ok, nil} = PolymorphicType.dump(nil, &Function.identity/1, %{mappings: @mappings})
  end

  test "dump/3: handles overrides" do
    expected = %{defaulted_override: "overridden!", non_default: "set", type: :advanced}

    out = PolymorphicType.dump(advanced_config(:struct, :all), &Function.identity/1, %{mappings: @mappings})
    assert {:ok, ^expected} = out
    assert !Map.has_key?(elem(out, 1), :defaulted)
  end

  test "load/3: handles nil" do
    assert {:ok, nil} = PolymorphicType.load(nil, &Function.identity/1, %{mappings: @mappings})
  end

  test "load/3: handles unsets and defaults" do
    expected = %AdvancedConfig{defaulted: "some default value", type: :advanced}

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
             PolymorphicType.load(advanced_config(:map, :all), &Function.identity/1, %{mappings: @mappings})
  end

  defp basic_config(format, preset)
  defp basic_config(:struct, :empty), do: %BasicConfig{}
  defp basic_config(:struct, :all), do: %BasicConfig{non_default: "set"}
  defp basic_config(:map, preset), do: Map.from_struct(basic_config(:struct, preset))

  defp advanced_config(format, preset)
  defp advanced_config(:struct, :empty), do: %AdvancedConfig{}
  defp advanced_config(:struct, :all), do: %AdvancedConfig{non_default: "set", defaulted_override: "overridden!"}
  defp advanced_config(:map, preset), do: Map.from_struct(advanced_config(:struct, preset))
end
