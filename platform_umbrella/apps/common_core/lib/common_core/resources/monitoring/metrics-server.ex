defmodule CommonCore.Resources.MetricsServer do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "metrics-server"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F

  resource(:service_account_metrics_server, _battery, state) do
    namespace = core_namespace(state)

    :service_account
    |> B.build_resource()
    |> B.name("metrics-server")
    |> B.namespace(namespace)
  end

  resource(:cluster_role_system_metrics_server_nanny) do
    rules = [%{"nonResourceURLs" => ["/metrics"], "verbs" => ["get"]}]

    :cluster_role
    |> B.build_resource()
    |> B.name("system:metrics-server-nanny")
    |> B.rules(rules)
  end

  resource(:cluster_role_system_metrics_server) do
    rules = [
      %{"apiGroups" => [""], "resources" => ["nodes/metrics"], "verbs" => ["get"]},
      %{
        "apiGroups" => [""],
        "resources" => ["pods", "nodes", "namespaces", "configmaps"],
        "verbs" => ["get", "list", "watch"]
      }
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("system:metrics-server")
    |> B.rules(rules)
  end

  resource(:cluster_role_binding_metrics_server_system_auth_delegator, _battery, state) do
    namespace = core_namespace(state)

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("metrics-server:system:auth-delegator")
    |> B.role_ref(B.build_cluster_role_ref("system:auth-delegator"))
    |> B.subject(B.build_service_account("metrics-server", namespace))
  end

  resource(:cluster_role_binding_system_metrics_server_nanny, _battery, state) do
    namespace = core_namespace(state)

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("system:metrics-server-nanny")
    |> B.role_ref(B.build_cluster_role_ref("system:metrics-server-nanny"))
    |> B.subject(B.build_service_account("metrics-server", namespace))
  end

  resource(:cluster_role_binding_system_metrics_server, _battery, state) do
    namespace = core_namespace(state)

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("system:metrics-server")
    |> B.role_ref(B.build_cluster_role_ref("system:metrics-server"))
    |> B.subject(B.build_service_account("metrics-server", namespace))
  end

  resource(:role_system_metrics_server_nanny, _battery, state) do
    namespace = core_namespace(state)

    rules = [
      %{"apiGroups" => [""], "resources" => ["pods"], "verbs" => ["get"]},
      %{
        "apiGroups" => ["apps"],
        "resourceNames" => ["metrics-server"],
        "resources" => ["deployments"],
        "verbs" => ["get", "patch"]
      }
    ]

    :role
    |> B.build_resource()
    |> B.name("system:metrics-server-nanny")
    |> B.namespace(namespace)
    |> B.rules(rules)
  end

  resource(:role_binding_metrics_server_nanny, _battery, state) do
    namespace = core_namespace(state)

    :role_binding
    |> B.build_resource()
    |> B.name("metrics-server-nanny")
    |> B.namespace(namespace)
    |> B.role_ref(B.build_role_ref("system:metrics-server-nanny"))
    |> B.subject(B.build_service_account("metrics-server", namespace))
  end

  resource(:role_binding_metrics_server_auth_reader, _battery, state) do
    namespace = core_namespace(state)

    :role_binding
    |> B.build_resource()
    |> B.name("metrics-server-auth-reader")
    |> B.namespace(namespace)
    |> B.role_ref(B.build_role_ref("extension-apiserver-authentication-reader"))
    |> B.subject(B.build_service_account("metrics-server", namespace))
  end

  resource(:config_map_metrics_server_nanny, _battery, state) do
    namespace = core_namespace(state)

    data =
      Map.put(
        %{},
        "NannyConfiguration",
        """
        apiVersion: nannyconfig/v1alpha1
        kind: NannyConfiguration
        baseCPU: 0m
        cpuPerNode: 1m
        baseMemory: 0Mi
        memoryPerNode: 2Mi
        """
      )

    :config_map
    |> B.build_resource()
    |> B.name("metrics-server-nanny-config")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:cluster_role_system_metrics_server_aggregated_reader) do
    rules = [
      %{"apiGroups" => ["metrics.k8s.io"], "resources" => ["pods", "nodes"], "verbs" => ["get", "list", "watch"]}
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("system:metrics-server-aggregated-reader")
    |> B.label("rbac.authorization.k8s.io/aggregate-to-admin", "true")
    |> B.label("rbac.authorization.k8s.io/aggregate-to-edit", "true")
    |> B.label("rbac.authorization.k8s.io/aggregate-to-view", "true")
    |> B.rules(rules)
  end

  resource(:service_metrics_server, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "https", "port" => 443, "protocol" => "TCP", "targetPort" => "https"}
      ])
      |> Map.put(
        "selector",
        %{"battery/app" => @app_name}
      )

    :service
    |> B.build_resource()
    |> B.name("metrics-server")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:deployment_metrics_server, battery, state) do
    namespace = core_namespace(state)

    template =
      %{
        "metadata" => %{
          "labels" => %{
            "battery/managed" => "true"
          }
        },
        "spec" => %{
          "containers" => [
            %{
              "args" => [
                "--secure-port=10250",
                "--cert-dir=/tmp",
                "--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname",
                "--kubelet-use-node-status-port",
                "--kubelet-insecure-tls",
                "--metric-resolution=15s",
                "--authorization-always-allow-paths=/metrics"
              ],
              "image" => battery.config.metrics_server_image,
              "imagePullPolicy" => "IfNotPresent",
              "livenessProbe" => %{
                "failureThreshold" => 3,
                "httpGet" => %{"path" => "/livez", "port" => "https", "scheme" => "HTTPS"},
                "initialDelaySeconds" => 0,
                "periodSeconds" => 10
              },
              "name" => "metrics-server",
              "ports" => [%{"containerPort" => 10_250, "name" => "https", "protocol" => "TCP"}],
              "readinessProbe" => %{
                "failureThreshold" => 3,
                "httpGet" => %{"path" => "/readyz", "port" => "https", "scheme" => "HTTPS"},
                "initialDelaySeconds" => 20,
                "periodSeconds" => 10
              },
              "resources" => %{"requests" => %{"cpu" => "100m", "memory" => "200Mi"}},
              "securityContext" => %{
                "allowPrivilegeEscalation" => false,
                "capabilities" => %{"drop" => ["ALL"]},
                "readOnlyRootFilesystem" => true,
                "runAsNonRoot" => true,
                "runAsUser" => 1000,
                "seccompProfile" => %{"type" => "RuntimeDefault"}
              },
              "volumeMounts" => [%{"mountPath" => "/tmp", "name" => "tmp"}]
            },
            %{
              "command" => [
                "/pod_nanny",
                "--config-dir=/etc/config",
                "--deployment=metrics-server",
                "--container=metrics-server",
                "--threshold=5",
                "--poll-period=300000",
                "--estimator=exponential",
                "--minClusterSize=100",
                "--use-metrics=true"
              ],
              "env" => [
                %{"name" => "MY_POD_NAME", "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.name"}}},
                %{"name" => "MY_POD_NAMESPACE", "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}}
              ],
              "image" => battery.config.addon_resizer_image,
              "name" => "metrics-server-nanny",
              "resources" => %{
                "limits" => %{"cpu" => "40m", "memory" => "25Mi"},
                "requests" => %{"cpu" => "40m", "memory" => "25Mi"}
              },
              "volumeMounts" => [%{"mountPath" => "/etc/config", "name" => "nanny-config-volume"}]
            }
          ],
          "priorityClassName" => "system-cluster-critical",
          "schedulerName" => nil,
          "serviceAccountName" => "metrics-server",
          "volumes" => [
            %{"emptyDir" => %{}, "name" => "tmp"},
            %{"configMap" => %{"name" => "metrics-server-nanny-config"}, "name" => "nanny-config-volume"}
          ]
        }
      }
      |> B.app_labels(@app_name)
      |> B.add_owner(battery)

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"battery/app" => @app_name}}
      )
      |> B.template(template)

    :deployment
    |> B.build_resource()
    |> B.name("metrics-server")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:api_service_v1beta1_metrics_k8s_io, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("group", "metrics.k8s.io")
      |> Map.put("groupPriorityMinimum", 100)
      |> Map.put("insecureSkipTLSVerify", true)
      |> Map.put(
        "service",
        %{"name" => "metrics-server", "namespace" => namespace, "port" => 443}
      )
      |> Map.put("version", "v1beta1")
      |> Map.put("versionPriority", 100)

    :api_service
    |> B.build_resource()
    |> B.name("v1beta1.metrics.k8s.io")
    |> B.spec(spec)
  end

  resource(:monitoring_service_monitor_metrics_server, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("endpoints", [
        %{
          "interval" => "1m",
          "path" => "/metrics",
          "port" => "https",
          "scheme" => "https",
          "scrapeTimeout" => "10s",
          "tlsConfig" => %{"insecureSkipVerify" => true}
        }
      ])
      |> Map.put("jobLabel", "metrics-server")
      |> Map.put("namespaceSelector", %{"matchNames" => [namespace]})
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"battery/app" => @app_name}}
      )

    :monitoring_service_monitor
    |> B.build_resource()
    |> B.name("metrics-server")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :victoria_metrics)
  end
end
