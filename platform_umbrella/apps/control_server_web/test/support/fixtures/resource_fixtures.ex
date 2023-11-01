defmodule ControlServerWeb.ResourceFixtures do
  @moduledoc false
  def resource_fixture(override_attrs \\ %{}) do
    defaults = %{
      kind: "Pod",
      name: Ecto.UUID.generate(),
      namespace: "battery-core",
      api_version: "v1",
      rest: %{}
    }

    attrs = Map.merge(defaults, override_attrs)

    # Different resources have different API versions:
    attrs =
      cond do
        attrs.kind in ["Pod", "Service", "Node"] ->
          Map.put(attrs, :api_version, "v1")

        attrs.kind in ["Deployment", "StatefulSet"] ->
          Map.put(attrs, :api_version, "apps/v1")
      end

    %{
      "apiVersion" => attrs.api_version,
      "kind" => attrs.kind,
      "metadata" => %{
        "name" => attrs.name,
        "namespace" => attrs.namespace,
        "labels" => %{
          "test-label" => "traefik-kube-system"
        }
      },
      "status" => %{
        "conditions" => [
          %{
            "lastTransitionTime" => "2023-08-23T02:36:14Z",
            "status" => "True",
            "type" => "Initialized"
          }
        ],
        "containerStatuses" => [
          %{
            "containerID" => "docker://5c21b18395d6896bcffc84ed76007726db69d15f76197ada5c7047ba4a2770d4",
            "image" => "rancher/mirrored-library-traefik:2.9.10",
            "imageID" => "docker://sha256:f7fa39db0cea458044cad085ee32cf6bb615ccff2f3f7bbbc5e57f9b36984afb",
            "lastState" => %{
              "terminated" => %{
                "containerID" => "docker://8e85ec15b4f4c4c8cbab1857bd83d3df362f2609e679b3a620ee5449395a7ab4",
                "exitCode" => 0,
                "finishedAt" => "2023-10-09T09:14:50Z",
                "reason" => "Completed",
                "startedAt" => "2023-10-08T23:54:01Z"
              }
            },
            "name" => "traefik",
            "ready" => true,
            "restartCount" => 5,
            "started" => true,
            "state" => %{"running" => %{"startedAt" => "2023-10-13T05:54:46Z"}}
          }
        ]
      }
    }
  end
end
