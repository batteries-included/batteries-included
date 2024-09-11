# test/common_core/util/ecto_validations_test.exs

defmodule CommonCore.Ecto.ValidationsTest do
  use ExUnit.Case

  import Ecto.Changeset

  alias CommonCore.Ecto.Validations
  alias CommonCore.Ecto.ValidationsTest.FooStruct

  defmodule FooStruct do
    @moduledoc false
    use TypedEctoSchema

    typed_schema "foo_struct" do
      field :foo, :string
      field :name, :string
      field :age, :integer
      field :bar, {:array, :string}
    end

    def changeset(foo, params) do
      foo
      |> cast(params, [:foo, :name, :age, :bar])
      |> validate_length(:name, min: 2)
    end
  end

  describe "downcase_fields/2" do
    test "downcases string fields" do
      changeset =
        %FooStruct{}
        |> cast(%{"name" => "JOHN"}, [:name])
        |> Validations.downcase_fields([:name])

      assert changeset.changes.name == "john"
    end

    test "ignores non-string fields" do
      changeset =
        %FooStruct{}
        |> cast(%{"age" => 42}, [:age])
        |> Validations.downcase_fields([:age])

      assert changeset.changes.age == 42
    end

    test "ignores nil fields" do
      changeset =
        %FooStruct{}
        |> cast(%{"name" => nil}, [:name])
        |> Validations.downcase_fields([:name])

      assert changeset.changes == %{}
    end
  end

  describe "trim_fields/2" do
    test "trim string fields" do
      changeset =
        %FooStruct{}
        |> cast(%{"name" => "  John "}, [:name])
        |> Validations.trim_fields([:name])

      assert changeset.changes.name == "John"
    end

    test "ignores non-string fields" do
      changeset =
        %FooStruct{}
        |> cast(%{"age" => 42}, [:age])
        |> Validations.trim_fields([:age])

      assert changeset.changes.age == 42
    end

    test "ignores nil fields" do
      changeset =
        %FooStruct{}
        |> cast(%{"name" => nil}, [:name])
        |> Validations.trim_fields([:name])

      assert changeset.changes == %{}
    end
  end

  describe "subforms_valid?/2" do
    test "returns true for valid subforms" do
      assert Validations.subforms_valid?(
               %{"foo" => %{name: "John"}, "extra_key" => %{}},
               %{"foo" => &FooStruct.changeset(%FooStruct{}, &1)}
             )
    end

    test "returns false for invalid subforms" do
      refute Validations.subforms_valid?(
               %{"foo" => %{name: "J"}},
               %{"foo" => &FooStruct.changeset(%FooStruct{}, &1)}
             )
    end
  end

  describe "add_item_to_list/3" do
    test "should add empty item to list" do
      changeset = FooStruct.changeset(%FooStruct{}, %{bar: []})

      assert Validations.add_item_to_list(changeset, :bar).changes == %{bar: [""]}
    end

    test "should add item to list" do
      changeset = FooStruct.changeset(%FooStruct{}, %{bar: []})

      assert Validations.add_item_to_list(changeset, :bar, "test").changes == %{bar: ["test"]}
    end
  end

  describe "remove_item_from_list/3" do
    test "should remove item from list" do
      changeset = FooStruct.changeset(%FooStruct{}, %{bar: ["test1", "test2"]})

      assert Validations.remove_item_from_list(changeset, :bar, 0).changes == %{bar: ["test2"]}
    end

    test "should remove last item from list" do
      changeset = FooStruct.changeset(%FooStruct{}, %{bar: ["test"]})

      assert Validations.remove_item_from_list(changeset, :bar, "0").changes == %{bar: []}
    end
  end
end
