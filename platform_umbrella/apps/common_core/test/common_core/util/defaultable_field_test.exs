defmodule CommonCore.Util.DefaultableFieldTest do
  use ExUnit.Case

  alias CommonCore.Util.DefaultableField

  defmodule TestA do
    @moduledoc false
    use DefaultableField
    use TypedEctoSchema

    typed_schema "test" do
      defaultable_field :a_defaultable_field, :string, default: "this is the default"
      defaultable_field :enum, Ecto.Enum, values: [:a, :b, :c], default: :a
    end
  end

  test "has virtual field in schema" do
    assert Enum.any?(TestA.__schema__(:virtual_fields), fn field -> field == :a_defaultable_field end)
    assert :string = TestA.__schema__(:virtual_type, :a_defaultable_field)

    assert Enum.any?(TestA.__schema__(:virtual_fields), fn field -> field == :enum end)
    assert {:parameterized, Ecto.Enum, _} = TestA.__schema__(:virtual_type, :enum)
  end

  test "has override field in schema" do
    assert Enum.any?(TestA.__schema__(:fields), fn field -> field == :a_defaultable_field_override end)
    assert :string = TestA.__schema__(:type, :a_defaultable_field_override)

    assert Enum.any?(TestA.__schema__(:fields), fn field -> field == :enum_override end)
    assert {:parameterized, Ecto.Enum, _} = TestA.__schema__(:type, :enum_override)
  end
end
