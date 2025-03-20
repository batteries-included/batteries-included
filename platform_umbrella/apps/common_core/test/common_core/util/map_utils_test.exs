defmodule CommonCore.Util.MapTest do
  use ExUnit.Case, async: true

  import CommonCore.Util.Map

  doctest CommonCore.Util.Map

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
end
