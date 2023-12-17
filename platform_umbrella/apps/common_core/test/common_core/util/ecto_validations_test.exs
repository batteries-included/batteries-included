# test/common_core/util/ecto_validations_test.exs

defmodule CommonCore.Util.EctoValidationsTest do
  use ExUnit.Case

  import Ecto.Changeset

  alias CommonCore.Util.EctoValidations
  alias CommonCore.Util.EctoValidationsTest.FooStruct

  defmodule FooStruct do
    @moduledoc false
    use TypedEctoSchema

    typed_schema "foo_struct" do
      field :foo, :string
      field :name, :string
      field :age, :integer
    end
  end

  describe "downcase_fields/2" do
    test "downcases string fields" do
      changeset =
        %FooStruct{}
        |> cast(%{"name" => "JOHN"}, [:name])
        |> EctoValidations.downcase_fields([:name])

      assert changeset.changes.name == "john"
    end

    test "ignores non-string fields" do
      changeset =
        %FooStruct{}
        |> cast(%{"age" => 42}, [:age])
        |> EctoValidations.downcase_fields([:age])

      assert changeset.changes.age == 42
    end

    test "ignores nil fields" do
      changeset =
        %FooStruct{}
        |> cast(%{"name" => nil}, [:name])
        |> EctoValidations.downcase_fields([:name])

      assert changeset.changes == %{}
    end
  end
end
