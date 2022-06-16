defmodule KubeExt.OwnerRefernceTest do
  use ExUnit.Case

  @empty %{}
  @empty_metadata %{"metadata" => %{}}
  @empty_owner_metadata %{"metadata" => %{"ownerReferences" => []}}
  @real_example %{
    "apiVersion" => "serving.knative.dev/v1",
    "kind" => "Revision",
    "metadata" => %{
      "annotations" => %{
        "serving.knative.dev/creator" => "system:admin",
        "serving.knative.dev/routes" => "echo",
        "serving.knative.dev/routingStateModified" => "2022-06-14T21:37:57Z"
      },
      "creationTimestamp" => "2022-06-14T21:37:57Z",
      "generation" => 1,
      "labels" => %{
        "serving.knative.dev/configuration" => "echo",
        "serving.knative.dev/configurationGeneration" => "1",
        "serving.knative.dev/configurationUID" => "8f92fa99-ea9c-493f-b16d-79ee42770571",
        "serving.knative.dev/routingState" => "active",
        "serving.knative.dev/service" => "echo",
        "serving.knative.dev/serviceUID" => "95a40cb1-4037-47e2-a81c-e64aea5f36ae"
      },
      "name" => "echo-00001",
      "namespace" => "battery-knative",
      "ownerReferences" => [
        %{
          "apiVersion" => "serving.knative.dev/v1",
          "blockOwnerDeletion" => true,
          "controller" => true,
          "kind" => "Configuration",
          "name" => "echo",
          "uid" => "8f92fa99-ea9c-493f-b16d-79ee42770571"
        }
      ],
      "resourceVersion" => "212062",
      "uid" => "ebb9861e-b5a0-45ef-9d91-453569c636ae"
    },
    "spec" => %{}
  }

  describe "KubeExt.OwnerRefernce" do
    test "return nil for un owned" do
      assert nil == KubeExt.OwnerRefernce.get_owner(@empty)
      assert nil == KubeExt.OwnerRefernce.get_owner(@empty_metadata)
      assert nil == KubeExt.OwnerRefernce.get_owner(@empty_owner_metadata)
    end

    test "return the uid for an owned" do
      assert "8f92fa99-ea9c-493f-b16d-79ee42770571" ==
               KubeExt.OwnerRefernce.get_owner(@real_example)
    end
  end
end
