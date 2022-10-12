defmodule KubeExt.HashingTest do
  use ExUnit.Case

  alias KubeExt.Hashing

  @service_one_json """
    {
      "apiVersion": "v1",
      "kind": "Service",
      "metadata": {
          "annotations": {
              "battery/hash": "yLCsuxcNKPXDUzo5SwaM60r5y/U="
          },
          "creationTimestamp": "2021-09-01T08:12:22Z",
          "labels": {
              "battery/app": "notebooks",
              "battery/managed": "True",
              "battery/notebook": "whiskey-frank"
          },
          "name": "notebook-whiskey-frank",
          "namespace": "battery-core",
          "resourceVersion": "884",
          "uid": "22484123-86ac-4050-aa60-22c81557ea2b"
      },
      "spec": {
          "clusterIP": "10.43.235.44",
          "clusterIPs": [
              "10.43.235.44"
          ],
          "ipFamilies": [
              "IPv4"
          ],
          "ipFamilyPolicy": "SingleStack",
          "ports": [
              {
                  "name": "http",
                  "port": 8888,
                  "protocol": "TCP",
                  "targetPort": 8888
              }
          ],
          "selector": {
              "battery/notebook": "whiskey-frank"
          },
          "sessionAffinity": "None",
          "type": "ClusterIP"
      },
      "status": {
          "loadBalancer": {}
      }
  }
  """

  @service_two %{
    "apiVersion" => "v1",
    "kind" => "Service",
    "metadata" => %{
      "annotations" => %{
        "battery/hash" => "AUR3TZXOZSZS2MOBXH2AGAKTRZGPEIJPGDWRJWR6H3OI47BGS45A===="
      },
      "labels" => %{
        "battery/app" => "notebooks",
        "battery/managed" => "True",
        "konghq.com/path" => "/x/notebooks/whiskey-frank"
      },
      "name" => "notebook-whiskey-frank",
      "namespace" => "battery-core"
    },
    "spec" => %{
      "ports" => [%{name: "http", port: 8888, targetPort: 8888}],
      "selector" => %{"battery/notebook" => "whiskey-frank"}
    }
  }

  test "Hashing.different?" do
    assert false == Hashing.different?([], [])
    assert false == Hashing.different?(%{test: 100}, %{test: 100})
  end

  test "LargeJson different?" do
    assert Hashing.different?(Jason.decode!(@service_one_json), @service_two)

    assert false ==
             Hashing.different?(
               Jason.decode!(@service_one_json),
               Jason.decode!(@service_one_json)
             )
  end

  test "stable with annotations" do
    assert false ==
             Hashing.different?(
               @service_two,
               @service_two
             )
  end

  test "recompute hash stable" do
    striped =
      @service_two
      |> update_in(~w(metadata), fn meta -> Map.drop(meta || %{}, ["annotations"]) end)

    assert false == Hashing.different?(@service_two, striped)
  end
end
