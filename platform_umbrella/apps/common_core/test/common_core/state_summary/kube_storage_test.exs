defmodule CommonCore.StateSummary.KubeStorageTest do
  use ExUnit.Case

  alias CommonCore.StateSummary
  alias CommonCore.StateSummary.KubeStorage

  describe "storage_classes/1" do
    test "returns all storage classes" do
      classes = [
        %{
          "metadata" => %{
            "name" => "standard",
            "annotations" => %{}
          }
        },
        %{
          "metadata" => %{
            "name" => "gold",
            "annotations" => %{}
          }
        }
      ]

      state = %StateSummary{kube_state: %{storage_class: classes}}
      assert KubeStorage.storage_classes(state) == classes
    end

    test "returns empty list if no classes" do
      state = %StateSummary{kube_state: %{}}
      assert KubeStorage.storage_classes(state) == []
    end
  end

  describe "default_storage_class/1" do
    test "returns the first class when no default" do
      classes = [
        %{"metadata" => %{"annotations" => %{}}},
        %{"metadata" => %{"annotations" => %{}}}
      ]

      assert KubeStorage.default_storage_class(%StateSummary{kube_state: %{storage_class: classes}}) ==
               List.first(classes)
    end

    test "returns the class marked as default" do
      classes = [
        %{"metadata" => %{"annotations" => %{}}},
        %{"metadata" => %{"annotations" => %{"storageclass.kubernetes.io/is-default-class" => "true"}}}
      ]

      # we should choose the one with the annotation
      assert KubeStorage.default_storage_class(%StateSummary{kube_state: %{storage_class: classes}}) == List.last(classes)
      # Don't rely on the order of the classes
      assert KubeStorage.default_storage_class(%StateSummary{kube_state: %{storage_class: classes}}) !=
               List.first(classes)
    end
  end
end
