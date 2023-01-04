defmodule KubeResources.VMCluster do
  use KubeExt.ResourceGenerator

  import CommonCore.SystemState.Namespaces
  import CommonCore.SystemState.Hosts

  alias KubeExt.Builder, as: B
  alias KubeExt.FilterResource, as: F
  alias KubeResources.IstioConfig.VirtualService

  @app_name "vcitoria-metrics-cluster"

  resource(:vm_cluster_main, battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("replicationFactor", 1)
      |> Map.put("retentionPeriod", "14")
      |> Map.put(
        "vminsert",
        %{
          "extraArgs" => %{},
          "image" => %{"tag" => battery.config.cluster_image_tag},
          "replicaCount" => battery.config.vminsert_replicas,
          "resources" => %{}
        }
      )
      |> Map.put(
        "vmselect",
        %{
          "cacheMountPath" => "/select-cache",
          # "extraArgs" => %{ "vmalert.proxyURL" => "http://vmalert-main-alert.#{namespace}.svc:8080" },
          "image" => %{"tag" => battery.config.cluster_image_tag},
          "replicaCount" => battery.config.vmselect_replicas,
          "resources" => %{},
          "storage" => %{
            "volumeClaimTemplate" => %{
              "spec" => %{
                "resources" => %{
                  "requests" => %{"storage" => battery.config.vmselect_volume_size}
                }
              }
            }
          }
        }
      )
      |> Map.put(
        "vmstorage",
        %{
          "image" => %{"tag" => battery.config.cluster_image_tag},
          "replicaCount" => battery.config.vmstorage_replicas,
          "resources" => %{},
          "storage" => %{
            "volumeClaimTemplate" => %{
              "spec" => %{
                "resources" => %{
                  "requests" => %{"storage" => battery.config.vmstorage_volume_size}
                }
              }
            }
          },
          "storageDataPath" => "/vm-data"
        }
      )

    B.build_resource(:vm_cluster)
    |> B.name("main-cluster")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(spec)
  end

  resource(:virtual_service, _battery, state) do
    namespace = core_namespace(state)

    spec = VirtualService.fallback("vmselect-main-cluster", hosts: [vmselect_host(state)])

    B.build_resource(:istio_virtual_service)
    |> B.name("vmselect")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(spec)
    |> F.require_battery(state, :istio_gateway)
  end
end
