defmodule KubeResources.VMCluster do
  use KubeResources.ResourceGenerator, app_name: "vcitoria-metrics-cluster"

  import CommonCore.StateSummary.Namespaces
  import CommonCore.StateSummary.Hosts

  alias KubeResources.Builder, as: B
  alias KubeResources.FilterResource, as: F
  alias KubeResources.IstioConfig.VirtualService

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
    |> B.spec(spec)
  end

  resource(:virtual_service, _battery, state) do
    namespace = core_namespace(state)

    spec = VirtualService.fallback("vmselect-main-cluster", hosts: [vmselect_host(state)])

    B.build_resource(:istio_virtual_service)
    |> B.name("vmselect")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :istio_gateway)
  end

  resource(:config_map_grafana_datasource, _battery, state) do
    namespace = core_namespace(state)

    datasources = %{
      "apiVersion" => 1,
      "datasources" => [
        %{
          "name" => "vmselect",
          "type" => "prometheus",
          "orgId" => 1,
          "isDefault" => true,
          "url" => "http://vmselect-main-cluster.#{namespace}.svc:8481/select/0/prometheus/"
        }
      ]
    }

    data = %{"vmselect-datasources.yaml" => Ymlr.document!(datasources)}

    B.build_resource(:config_map)
    |> B.name("grafana-datasource-vmselect")
    |> B.namespace(namespace)
    |> B.data(data)
    |> B.label("grafana_datasource", "1")
    |> F.require_battery(state, :grafana)
  end
end
