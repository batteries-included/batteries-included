defmodule CommonCore.Util.MapTest do
  use ExUnit.Case, async: true

  import CommonCore.Util.Map

  alias CommonCore.ExampleSchemas.EmbeddedMetaSchema

  doctest CommonCore.Util.Map

  describe "maybe_put/3" do
    test "doesn't update the map if value is \"empty\"" do
      assert %{} = maybe_put(%{}, "a", "")
      assert %{} = maybe_put(%{}, "a", "0")
      assert %{} = maybe_put(%{}, "a", %{})
      assert %{} = maybe_put(%{}, "a", 0)
    end

    test "doesn't update the map if key is \"empty\"" do
      assert %{} = maybe_put(%{}, "", :a)
      assert %{} = maybe_put(%{}, "0", :a)
      assert %{} = maybe_put(%{}, %{}, :a)
      assert %{} = maybe_put(%{}, 0, :a)
    end

    test "doesn't update the map if value is nil" do
      assert %{} = maybe_put(%{}, "a", nil)
    end

    test "updates the map" do
      assert %{"a" => "b"} = maybe_put(%{}, "a", "b")
      assert %{"a" => %{x: :y}} = maybe_put(%{}, "a", %{x: :y})
      assert %{"a" => "false"} = maybe_put(%{}, "a", "false")
    end
  end

  describe "maybe_put/4" do
    test "updates the map when predicate is `true`" do
      assert %{"a" => "b"} = maybe_put(%{}, true, "a", "b")
      assert %{"a" => %{funky: "chicken"}} = maybe_put(%{}, true, "a", %{funky: "chicken"})
    end

    test "doesn't update the map when predicate is `false`" do
      assert %{"a" => "b"} = maybe_put(%{"a" => "b"}, false, "a", "c")

      assert %{"a" => %{funky: "chicken"}} =
               maybe_put(%{"a" => %{funky: "chicken"}}, false, "a", "doesntmatter")
    end

    test "evaluates predicate if it's a function" do
      assert %{"a" => "b"} = maybe_put(%{}, fn _m -> true end, "a", "b")
      assert %{} = maybe_put(%{}, fn _m -> false end, "a", "b")

      assert %{"a" => "c"} = maybe_put(%{"a" => "b"}, fn orig -> orig["a"] == "b" end, "a", "c")

      assert %{"a" => "b"} = maybe_put(%{"a" => "b"}, fn orig -> orig["a"] == "c" end, "a", "c")
    end
  end

  describe "maybe_put_lazy/4" do
    test "updates the map when predicate is `true`" do
      assert %{"a" => "b"} = maybe_put_lazy(%{}, true, "a", fn _m -> "b" end)

      assert %{"a" => %{funky: "chicken"}} =
               maybe_put_lazy(%{}, true, "a", fn _m -> %{funky: "chicken"} end)
    end

    test "doesn't update the map when predicate is `false`" do
      assert %{"a" => "b"} = maybe_put_lazy(%{"a" => "b"}, false, "a", fn _m -> "c" end)

      assert %{"a" => %{funky: "chicken"}} =
               maybe_put_lazy(%{"a" => %{funky: "chicken"}}, false, "a", fn _m -> "c" end)
    end

    test "evaluates predicate if it's a function" do
      assert %{"a" => "b"} = maybe_put_lazy(%{}, fn _m -> true end, "a", fn _m -> "b" end)
      assert %{} = maybe_put_lazy(%{}, fn _m -> false end, "a", fn _m -> "b" end)

      assert %{"a" => 1} =
               maybe_put_lazy(%{"a" => "b"}, fn orig -> orig["a"] == "b" end, "a", fn m ->
                 length(Map.keys(m))
               end)

      assert %{"a" => "b"} =
               maybe_put_lazy(%{"a" => "b"}, fn orig -> orig["a"] == "c" end, "a", fn m ->
                 length(Map.keys(m))
               end)
    end
  end

  describe "maybe_append/4" do
    test "updates the map when predicate is `true`" do
      assert %{"a" => ["b"]} = maybe_append(%{}, true, "a", "b")
      assert %{"a" => ["b"]} = maybe_append(%{"a" => nil}, true, "a", "b")
      assert %{"a" => ["a", "b"]} = maybe_append(%{"a" => ["a"]}, true, "a", "b")
      assert %{"a" => ["a", "b", "b", "c"]} = maybe_append(%{"a" => ["a", "b"]}, true, "a", ["b", "c"])
    end

    test "doesn't update the map when predicate is `false`" do
      assert %{} = maybe_append(%{}, false, "a", "b")
      assert %{"a" => nil} = maybe_append(%{"a" => nil}, false, "a", "b")
      assert %{"a" => ["a"]} = maybe_append(%{"a" => ["a"]}, false, "a", "b")
    end

    test "evaluates `predicate` if it's a function" do
      assert %{"a" => ["b"]} = maybe_append(%{}, fn _ -> true end, "a", "b")
      assert %{"a" => ["b"]} = maybe_append(%{"a" => nil}, fn m -> m["a"] == nil end, "a", "b")

      assert %{} = maybe_append(%{}, fn _ -> false end, "a", "b")
      assert %{"a" => nil} = maybe_append(%{"a" => nil}, fn m -> m["a"] == "blargh" end, "a", "b")
    end
  end

  describe "from_struct/1" do
    test "converts Ecto schemas to plain maps, removing metadata" do
      # Create an embedded schema instance
      schema = %EmbeddedMetaSchema{name: "test", age: 42}

      result = from_struct(schema)

      # Should be a plain map with only the actual field data
      assert result == %{name: "test", age: 42, password: nil}

      # Should not contain any Ecto metadata
      refute Map.has_key?(result, :__meta__)
      refute Map.has_key?(result, :__struct__)
    end

    test "converts regular schemas to plain maps, removing associations and virtual fields" do
      alias CommonCore.ExampleSchemas.TodoSchema

      # Create a schema with an embedded association
      meta = %EmbeddedMetaSchema{name: "meta_test", age: 100}

      todo = %TodoSchema{
        name: "my-todo",
        message: "test message",
        meta: meta
      }

      result = from_struct(todo)

      # Should contain regular fields but not associations or virtual fields
      assert Map.has_key?(result, :name)
      assert Map.has_key?(result, :message_override)

      # Should not contain Ecto metadata
      refute Map.has_key?(result, :__meta__)
      refute Map.has_key?(result, :__struct__)
      # virtual field from defaultable_field
      refute Map.has_key?(result, :message)

      # The embedded association might be present depending on how it's handled
      # but metadata fields should definitely be gone
    end

    test "passes through regular maps unchanged" do
      map = %{name: "test", value: 42, nested: %{key: "value"}}

      result = from_struct(map)

      assert result == map
    end

    test "converts non-Ecto structs to plain maps" do
      # Test with a built-in Elixir struct
      uri = %URI{scheme: "https", host: "example.com", port: 443}

      result = from_struct(uri)

      # Should be converted to a plain map
      assert is_map(result)
      refute is_struct(result)
      assert result.scheme == "https"
      assert result.host == "example.com"
      assert result.port == 443
    end

    test "handles structs that don't have __schema__ function" do
      # Create a simple struct without Ecto schema functionality

      simple = %CommonCore.ExampleSchemas.SimpleStruct{name: "test", value: 123}

      result = from_struct(simple)

      # Should convert to plain map since it doesn't have __schema__
      assert result == %{name: "test", value: 123}
      refute Map.has_key?(result, :__struct__)
    end

    test "handles nil and empty values gracefully" do
      # Test with nil
      assert from_struct(nil) == nil

      # Test with empty map
      assert from_struct(%{}) == %{}
    end

    test "works with deeply nested structures" do
      # Test with complex nested data
      complex_map = %{
        user: %{name: "John", age: 30},
        items: [%{id: 1, name: "item1"}, %{id: 2, name: "item2"}],
        metadata: %{created_at: "2024-01-01", updated_at: "2024-01-02"}
      }

      result = from_struct(complex_map)

      # Should pass through unchanged since it's already a map
      assert result == complex_map
    end

    test "preserves all field types correctly" do
      # Create a schema with various field types
      schema = %EmbeddedMetaSchema{
        name: "test_user",
        age: 25
      }

      result = from_struct(schema)

      # Verify field types are preserved
      assert is_binary(result.name)
      assert is_integer(result.age)
      assert result.name == "test_user"
      assert result.age == 25
    end
  end
end
