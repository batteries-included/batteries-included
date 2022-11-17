defmodule KubeResources.Promtail do
  use KubeExt.IncludeResource, promtail_yaml: "priv/raw_files/promtail/promtail.yaml"
  use KubeExt.ResourceGenerator

  import KubeExt.SystemState.Namespaces

  alias KubeExt.Builder, as: B
  alias KubeExt.Secret

  @app_name "promtail"

  resource(:cluster_role_binding_main, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:cluster_role_binding)
    |> B.name("promtail")
    |> B.app_labels(@app_name)
    |> B.role_ref(B.build_cluster_role_ref("promtail"))
    |> B.subject(B.build_service_account("promtail", namespace))
  end

  resource(:cluster_role_main) do
    B.build_resource(:cluster_role)
    |> B.name("promtail")
    |> B.app_labels(@app_name)
    |> B.rules([
      %{
        "apiGroups" => [""],
        "resources" => ["nodes", "nodes/proxy", "services", "endpoints", "pods"],
        "verbs" => ["get", "watch", "list"]
      }
    ])
  end

  resource(:daemon_set_main, battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:daemon_set)
    |> B.name("promtail")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(%{
      "selector" => %{
        "matchLabels" => %{"battery/app" => @app_name}
      },
      "template" => %{
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
              "image" => battery.config.image,
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
      },
      "updateStrategy" => %{}
    })
  end

  resource(:secret_main, _battery, state) do
    namespace = core_namespace(state)
    data = %{} |> Map.put("promtail.yaml", get_resource(:promtail_yaml)) |> Secret.encode()

    B.build_resource(:secret)
    |> B.name("promtail")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.data(data)
  end

  resource(:service_account_main, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:service_account)
    |> B.name("promtail")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
  end

  resource(:service_metrics, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:service)
    |> B.name("promtail-metrics")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(%{
      "ports" => [
        %{
          "name" => "http-metrics",
          "port" => 3101,
          "protocol" => "TCP",
          "targetPort" => "http-metrics"
        }
      ],
      "selector" => %{"battery/app" => @app_name}
    })
  end

  resource(:service_monitor_main, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:service_monitor)
    |> B.name("promtail")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(%{
      "endpoints" => [%{"port" => "http-metrics"}],
      "selector" => %{
        "matchLabels" => %{"battery/app" => @app_name}
      }
    })
  end
end
