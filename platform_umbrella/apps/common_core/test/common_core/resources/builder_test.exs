defmodule CommonCore.Resources.BuilderTest do
  use ExUnit.Case

  import CommonCore.Resources.Builder

  describe "short_selector/2" do
    test "adds battery/app selector" do
      assert %{"selector" => %{"battery/app" => "a"}} = short_selector(%{}, "a")
    end
  end

  describe "short_selector/3" do
    test "adds selector" do
      assert %{"selector" => %{"a" => "b"}} = short_selector(%{}, "a", "b")

      assert %{"selector" => %{"c" => "d"}} =
               %{}
               |> short_selector("a", "b")
               |> short_selector("c", "d")
    end

    test "is idempotent" do
      assert %{"selector" => %{"a" => "b"}} =
               %{}
               |> short_selector("a", "b")
               |> short_selector("a", "b")
    end
  end

  describe "match_labels_selector/2" do
    test "adds battery/app matchLabels" do
      assert %{"selector" => %{"matchLabels" => %{"battery/app" => "b"}}} = match_labels_selector(%{}, "b")
    end
  end

  describe "match_labels_selector/3" do
    test "adds matchLabels" do
      assert %{"selector" => %{"matchLabels" => %{"a" => "b"}}} = match_labels_selector(%{}, "a", "b")
    end

    test "is idempotent" do
      assert %{"selector" => %{"matchLabels" => %{"a" => "b"}}} =
               %{}
               |> match_labels_selector("a", "b")
               |> match_labels_selector("a", "b")
    end

    test "updates existing matchLabels" do
      existing = %{"selector" => %{"matchLabels" => %{"a" => "b"}}}
      assert %{"selector" => %{"matchLabels" => %{"a" => "c"}}} = match_labels_selector(existing, "a", "c")
      assert %{"selector" => %{"matchLabels" => %{"a" => "b", "b" => "c"}}} = match_labels_selector(existing, "b", "c")
    end

    test "will chain with other labels" do
      assert %{"selector" => %{"matchLabels" => %{"a" => "b"}, "battery/app" => "myapp", "d" => "e"}} =
               %{}
               |> match_labels_selector("a", "b")
               |> short_selector("myapp")
               |> short_selector("d", "e")

      assert %{"selector" => %{"matchLabels" => %{"a" => "b"}, "battery/app" => "myapp", "d" => "e"}} =
               %{}
               |> short_selector("myapp")
               |> match_labels_selector("a", "b")
               |> short_selector("d", "e")

      assert %{"selector" => %{"matchLabels" => %{"a" => "b"}, "battery/app" => "myapp", "d" => "e"}} =
               %{}
               |> short_selector("myapp")
               |> short_selector("d", "e")
               |> match_labels_selector("a", "b")
    end
  end
end
