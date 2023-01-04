defmodule KubeResources.NodeExporter do
  use KubeExt.ResourceGenerator

  import CommonCore.SystemState.Namespaces

  alias KubeExt.Builder, as: B
  alias KubeExt.FilterResource, as: F

  @app_name "node-exporter"

  resource(:service_account_node_exporter_prometheus_node_exporter, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:service_account)
    |> B.name("node-exporter")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
  end

  resource(:daemon_set_node_exporter_prometheus_node_exporter, battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put(
        "selector",
        %{
          "matchLabels" => %{
            "battery/app" => @app_name
          }
        }
      )
      |> Map.put(
        "template",
        %{
          "metadata" => %{
            "annotations" => %{"cluster-autoscaler.kubernetes.io/safe-to-evict" => "true"},
            "labels" => %{
              "battery/app" => @app_name,
              "battery/managed" => "true"
            }
          },
          "spec" => %{
            "automountServiceAccountToken" => false,
            "containers" => [
              %{
                "args" => [
                  "--path.procfs=/host/proc",
                  "--path.sysfs=/host/sys",
                  "--path.rootfs=/host/root",
                  "--web.listen-address=[$(HOST_IP)]:9100"
                ],
                "env" => [%{"name" => "HOST_IP", "value" => "0.0.0.0"}],
                "image" => battery.config.image,
                "imagePullPolicy" => "IfNotPresent",
                "livenessProbe" => %{
                  "failureThreshold" => 3,
                  "httpGet" => %{
                    "httpHeaders" => nil,
                    "path" => "/",
                    "port" => 9100,
                    "scheme" => "HTTP"
                  },
                  "initialDelaySeconds" => 0,
                  "periodSeconds" => 10,
                  "successThreshold" => 1,
                  "timeoutSeconds" => 1
                },
                "name" => "node-exporter",
                "ports" => [%{"containerPort" => 9100, "name" => "metrics", "protocol" => "TCP"}],
                "readinessProbe" => %{
                  "failureThreshold" => 3,
                  "httpGet" => %{
                    "httpHeaders" => nil,
                    "path" => "/",
                    "port" => 9100,
                    "scheme" => "HTTP"
                  },
                  "initialDelaySeconds" => 0,
                  "periodSeconds" => 10,
                  "successThreshold" => 1,
                  "timeoutSeconds" => 1
                },
                "volumeMounts" => [
                  %{"mountPath" => "/host/proc", "name" => "proc", "readOnly" => true},
                  %{"mountPath" => "/host/sys", "name" => "sys", "readOnly" => true},
                  %{
                    "mountPath" => "/host/root",
                    "mountPropagation" => "HostToContainer",
                    "name" => "root",
                    "readOnly" => true
                  }
                ]
              }
            ],
            "hostNetwork" => true,
            "hostPID" => true,
            "securityContext" => %{
              "fsGroup" => 65_534,
              "runAsGroup" => 65_534,
              "runAsNonRoot" => true,
              "runAsUser" => 65_534
            },
            "serviceAccountName" => "node-exporter",
            "tolerations" => [%{"effect" => "NoSchedule", "operator" => "Exists"}],
            "volumes" => [
              %{"hostPath" => %{"path" => "/proc"}, "name" => "proc"},
              %{"hostPath" => %{"path" => "/sys"}, "name" => "sys"},
              %{"hostPath" => %{"path" => "/"}, "name" => "root"}
            ]
          }
        }
      )
      |> Map.put(
        "updateStrategy",
        %{"rollingUpdate" => %{"maxUnavailable" => 1}, "type" => "RollingUpdate"}
      )

    B.build_resource(:daemon_set)
    |> B.name("node-exporter")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(spec)
  end

  resource(:monitoring_service_monitor_node_exporter_prometheus_node_exporter, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("endpoints", [
        %{"port" => "metrics", "scheme" => "http", "scrapeTimeout" => "10s"}
      ])
      |> Map.put("jobLabel", "app.kubernetes.io/name")
      |> Map.put(
        "selector",
        %{
          "matchLabels" => %{
            "battery/app" => @app_name
          }
        }
      )

    B.build_resource(:monitoring_service_monitor)
    |> B.name("node-exporter")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(spec)
    |> F.require_battery(state, :victoria_metrics)
  end

  resource(:service_node_exporter_prometheus_node_exporter, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "metrics", "port" => 9100, "protocol" => "TCP", "targetPort" => 9100}
      ])
      |> Map.put(
        "selector",
        %{"battery/app" => @app_name}
      )

    B.build_resource(:service)
    |> B.name("node-exporter")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(spec)
    |> F.require_battery(state, :victoria_metrics)
  end
end
