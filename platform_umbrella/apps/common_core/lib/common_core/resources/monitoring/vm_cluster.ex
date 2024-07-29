defmodule CommonCore.Resources.VMCluster do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "victoria-metrics-cluster"

  import CommonCore.StateSummary.Hosts
  import CommonCore.StateSummary.Namespaces

  alias CommonCore.OpenAPI.IstioVirtualService.VirtualService
  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.Resources.ProxyUtils, as: PU
  alias CommonCore.Resources.VirtualServiceBuilder, as: V

  @vm_select_port 8481
  @instance_name "main-cluster"
  @select_k8s_name "vmselect"

  resource(:vm_cluster_main, battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("replicationFactor", battery.config.replication_factor)
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

    :vm_cluster
    |> B.build_resource()
    |> B.name(@instance_name)
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:virtual_service_main, battery, state) do
    namespace = core_namespace(state)

    spec =
      [hosts: vmselect_hosts(state)]
      |> VirtualService.new!()
      |> V.prefix(PU.prefix(battery), PU.service_name(battery), PU.port(battery))
      |> V.fallback("vmselect-main-cluster", @vm_select_port)

    :istio_virtual_service
    |> B.build_resource()
    |> B.name(@select_k8s_name)
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
          "name" => @select_k8s_name,
          "type" => "prometheus",
          "orgId" => 1,
          "isDefault" => true,
          "url" => "http://vmselect-main-cluster.#{namespace}.svc.cluster.local:#{@vm_select_port}/select/0/prometheus/"
        }
      ]
    }

    data = %{"vmselect-datasources.yaml" => Ymlr.document!(datasources)}

    :config_map
    |> B.build_resource()
    |> B.name("grafana-datasource-vmselect")
    |> B.namespace(namespace)
    |> B.data(data)
    |> B.label("grafana_datasource", "1")
    |> F.require_battery(state, :grafana)
  end

  resource(:istio_request_auth, _battery, state) do
    namespace = core_namespace(state)

    spec =
      state
      |> PU.request_auth()
      |> B.match_labels_selector("app.kubernetes.io/name", @select_k8s_name)
      |> B.match_labels_selector("app.kubernetes.io/instance", @instance_name)

    :istio_request_auth
    |> B.build_resource()
    |> B.name("#{@select_k8s_name}-keycloak-auth")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :sso)
  end

  resource(:istio_auth_policy, battery, state) do
    namespace = core_namespace(state)

    spec =
      state
      |> vmselect_host()
      |> List.wrap()
      |> PU.auth_policy(battery)
      |> B.match_labels_selector("app.kubernetes.io/name", @select_k8s_name)
      |> B.match_labels_selector("app.kubernetes.io/instance", @instance_name)

    :istio_auth_policy
    |> B.build_resource()
    |> B.name("#{@select_k8s_name}-require-keycloak-auth")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :sso)
  end
end
