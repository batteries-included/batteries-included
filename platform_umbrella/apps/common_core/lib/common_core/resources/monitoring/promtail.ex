defmodule CommonCore.Resources.Promtail do
  @moduledoc false
  use CommonCore.IncludeResource, promtail_yaml: "priv/raw_files/promtail/promtail.yaml"
  use CommonCore.Resources.ResourceGenerator, app_name: "promtail"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.Resources.Secret

  resource(:cluster_role_binding_main, _battery, state) do
    namespace = core_namespace(state)

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("promtail")
    |> B.role_ref(B.build_cluster_role_ref("promtail"))
    |> B.subject(B.build_service_account("promtail", namespace))
  end

  resource(:cluster_role_main) do
    rules = [
      %{
        "apiGroups" => [""],
        "resources" => ["nodes", "nodes/proxy", "services", "endpoints", "pods"],
        "verbs" => ["get", "watch", "list"]
      }
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("promtail")
    |> B.rules(rules)
  end

  resource(:service_account_main, _battery, state) do
    namespace = core_namespace(state)

    :service_account
    |> B.build_resource()
    |> B.name("promtail")
    |> B.namespace(namespace)
  end

  resource(:daemon_set_main, _battery, state) do
    namespace = core_namespace(state)

    template = %{
      "metadata" => %{
        "labels" => %{
          "battery/app" => @app_name,
          "battery/managed" => "true"
        }
      },
      "spec" => %{
        "containers" => [
          %{
            "args" => ["-config.file=/etc/promtail/promtail.yaml"],
            "env" => [
              %{
                "name" => "HOSTNAME",
                "valueFrom" => %{"fieldRef" => %{"fieldPath" => "spec.nodeName"}}
              }
            ],
            "image" => "docker.io/grafana/promtail:2.7.0",
            "imagePullPolicy" => "IfNotPresent",
            "name" => "promtail",
            "ports" => [
              %{"containerPort" => 3101, "name" => "http-metrics", "protocol" => "TCP"}
            ],
            "readinessProbe" => %{
              "failureThreshold" => 5,
              "httpGet" => %{"path" => "/ready", "port" => "http-metrics"},
              "initialDelaySeconds" => 10,
              "periodSeconds" => 10,
              "successThreshold" => 1,
              "timeoutSeconds" => 1
            },
            "securityContext" => %{
              "allowPrivilegeEscalation" => false,
              "capabilities" => %{"drop" => ["ALL"]},
              "readOnlyRootFilesystem" => true
            },
            "volumeMounts" => [
              %{"mountPath" => "/etc/promtail", "name" => "config"},
              %{"mountPath" => "/run/promtail", "name" => "run"},
              %{
                "mountPath" => "/var/lib/docker/containers",
                "name" => "containers",
                "readOnly" => true
              },
              %{"mountPath" => "/var/log/pods", "name" => "pods", "readOnly" => true}
            ]
          }
        ],
        "enableServiceLinks" => true,
        "securityContext" => %{"runAsGroup" => 0, "runAsUser" => 0},
        "serviceAccountName" => "promtail",
        "tolerations" => [
          %{
            "effect" => "NoSchedule",
            "key" => "node-role.kubernetes.io/master",
            "operator" => "Exists"
          },
          %{
            "effect" => "NoSchedule",
            "key" => "node-role.kubernetes.io/control-plane",
            "operator" => "Exists"
          }
        ],
        "volumes" => [
          %{"name" => "config", "secret" => %{"secretName" => "promtail"}},
          %{"hostPath" => %{"path" => "/run/promtail"}, "name" => "run"},
          %{"hostPath" => %{"path" => "/var/lib/docker/containers"}, "name" => "containers"},
          %{"hostPath" => %{"path" => "/var/log/pods"}, "name" => "pods"}
        ]
      }
    }

    spec =
      %{}
      |> Map.put("selector", %{"matchLabels" => %{"battery/app" => @app_name}})
      |> Map.put("template", template)
      |> Map.put("updateStrategy", %{})

    :daemon_set
    |> B.build_resource()
    |> B.name("promtail")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:secret_main, _battery, state) do
    namespace = core_namespace(state)

    data =
      %{}
      |> Map.put("promtail.yaml", get_resource(:promtail_yaml))
      |> Secret.encode()

    :secret
    |> B.build_resource()
    |> B.name("promtail")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:service_metrics, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{
          "name" => "http-metrics",
          "port" => 3101,
          "protocol" => "TCP",
          "targetPort" => "http-metrics"
        }
      ])
      |> Map.put("selector", %{"battery/app" => @app_name})

    :service
    |> B.build_resource()
    |> B.name("promtail-metrics")
    |> B.namespace(namespace)
    |> B.component_label("metrics")
    |> B.spec(spec)
    |> F.require_battery(state, :victoria_metrics)
  end

  resource(:monitoring_service_monitor_main, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("endpoints", [%{"port" => "http-metrics", "scheme" => "http"}])
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"battery/app" => @app_name, "battery/component" => "metrics"}}
      )

    :monitoring_service_monitor
    |> B.build_resource()
    |> B.name("promtail")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :victoria_metrics)
  end
end
