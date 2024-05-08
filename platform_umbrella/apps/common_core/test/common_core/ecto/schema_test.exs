defmodule CommonCore.Ecto.SchemaTest do
  use ExUnit.Case

  describe "CommonCore.Ecto.Schema" do
    alias CommonCore.ExampleSchemas.TodoSchema

    test "cast name" do
      # Fields are cast even without defining a cast function or changeset
      changeset = TodoSchema.changeset(%TodoSchema{}, %{name: "my todo"})
      todo = Ecto.Changeset.apply_changes(changeset)
      assert todo.name == "my todo"
    end

    test "images have a default value" do
      changeset = TodoSchema.changeset(%TodoSchema{}, %{})
      todo = Ecto.Changeset.apply_changes(changeset)
      assert todo.image == "mycontainer:latest"
    end

    test "default values are overwritten" do
      changeset = TodoSchema.changeset(%TodoSchema{}, %{image_override: "mycontainer:1.0"})
      todo = Ecto.Changeset.apply_changes(changeset)
      assert todo.image == "mycontainer:1.0"
    end

    test "passwords get a unique value each time" do
      changeset1 = TodoSchema.changeset(%TodoSchema{}, %{name: "todo1"})
      changeset2 = TodoSchema.changeset(%TodoSchema{}, %{name: "todo2"})
      todo1 = Ecto.Changeset.apply_changes(changeset1)
      todo2 = Ecto.Changeset.apply_changes(changeset2)

      refute todo1.password == todo2.password
    end

    test "passwords are the correct length" do
      changeset = TodoSchema.changeset(%TodoSchema{}, %{})
      todo = Ecto.Changeset.apply_changes(changeset)
      assert byte_size(todo.short_password) == 8
    end

    test "includes embeded schema" do
      changeset = TodoSchema.changeset(%TodoSchema{}, %{meta: %{name: "mynewname"}})
      todo = Ecto.Changeset.apply_changes(changeset)
      assert todo.meta.name == "mynewname"
    end

    test "embedded schema can have a secret field" do
      changeset = TodoSchema.changeset(%TodoSchema{}, %{meta: %{}})
      todo = Ecto.Changeset.apply_changes(changeset)
      assert todo.meta.password != nil
      assert byte_size(todo.meta.password) == 64
    end

    test "embedded schema runs validations" do
      changeset = TodoSchema.changeset(%TodoSchema{}, %{meta: %{name: "admin"}})
      assert {:error, changeset} = Ecto.Changeset.apply_action(changeset, :validate)
      assert changeset.changes.meta.errors[:name] != nil
    end

    test "embedded schemas can have default values" do
      changeset = TodoSchema.changeset(%TodoSchema{}, %{meta: %{}})
      todo = Ecto.Changeset.apply_changes(changeset)
      assert todo.meta.age == 100
    end
  end

  describe "CommonCore.Ecto.Schema + PolymorphicEmbeds" do
    alias CommonCore.ExamplePolySchema.BarPayloadSchema
    alias CommonCore.ExamplePolySchema.FooPayloadSchema
    alias CommonCore.ExamplePolySchema.RootSchema

    test "cast polymorphic schema" do
      changeset = RootSchema.changeset(%RootSchema{}, %{name: "myroot", payload: %{type: :foo}})
      root = Ecto.Changeset.apply_changes(changeset)
      assert root.payload.setting_a == "FooValueA"
      assert root.name == "myroot"
    end

    test "can take in existing payload" do
      changeset = RootSchema.changeset(%RootSchema{payload: BarPayloadSchema.new!()}, %{name: "myroot"})
      root = Ecto.Changeset.apply_changes(changeset)
      assert root.payload.setting_a == "BarValueA"
    end

    test "can take in existing payload with type" do
      starting = %RootSchema{payload: FooPayloadSchema.new!()}
      assert starting.payload.setting_a == "FooValueA"

      changeset = RootSchema.changeset(starting, %{name: "myroot", payload: %{type: :bar}})

      root = Ecto.Changeset.apply_changes(changeset)
      assert root.payload.setting_a == "BarValueA"
      assert root.payload.type == :bar
    end
  end
end
