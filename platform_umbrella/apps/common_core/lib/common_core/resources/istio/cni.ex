defmodule CommonCore.Resources.Istio.CNI do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "istio-cni"

  alias CommonCore.Defaults.Images
  alias CommonCore.Resources.Builder, as: B

  resource(:cluster_role_binding_istio_cni, battery, _state) do
    namespace = battery.config.namespace

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("istio-cni")
    |> B.role_ref(B.build_cluster_role_ref("istio-cni"))
    |> B.subject(B.build_service_account("istio-cni", namespace))
  end

  resource(:cluster_role_binding_istio_cni_ambient, battery, _state) do
    namespace = battery.config.namespace

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("istio-cni-ambient")
    |> B.role_ref(B.build_cluster_role_ref("istio-cni-ambient"))
    |> B.subject(B.build_service_account("istio-cni", namespace))
  end

  resource(:cluster_role_binding_istio_cni_repair_rolebinding, battery, _state) do
    namespace = battery.config.namespace

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("istio-cni-repair-rolebinding")
    |> B.role_ref(B.build_cluster_role_ref("istio-cni-repair-role"))
    |> B.subject(B.build_service_account("istio-cni", namespace))
  end

  resource(:cluster_role_istio_cni) do
    rules = [
      %{
        "apiGroups" => [""],
        "resources" => ["pods", "nodes", "namespaces"],
        "verbs" => ["get", "list", "watch"]
      }
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("istio-cni")
    |> B.rules(rules)
  end

  resource(:cluster_role_istio_cni_ambient) do
    rules = [
      %{"apiGroups" => [""], "resources" => ["pods/status"], "verbs" => ["patch", "update"]},
      %{
        "apiGroups" => ["apps"],
        "resourceNames" => ["istio-cni-node"],
        "resources" => ["daemonsets"],
        "verbs" => ["get"]
      }
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("istio-cni-ambient")
    |> B.rules(rules)
  end

  resource(:cluster_role_istio_cni_repair) do
    rules = [
      %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["create", "patch"]},
      %{"apiGroups" => [""], "resources" => ["pods"], "verbs" => ["watch", "get", "list"]}
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("istio-cni-repair-role")
    |> B.rules(rules)
  end

  resource(:config_map_istio_cni, battery, _state) do
    namespace = battery.config.namespace

    agent_version =
      :istio_cni |> Images.get_image!() |> Map.get(:default_tag) |> String.replace("-distroless", "")

    data =
      %{}
      |> Map.put("AMBIENT_DNS_CAPTURE", "true")
      |> Map.put("AMBIENT_ENABLED", "true")
      |> Map.put("AMBIENT_IPV6", "true")
      |> Map.put("AMBIENT_RECONCILE_POD_RULES_ON_STARTUP", "false")
      |> Map.put("CHAINED_CNI_PLUGIN", "true")
      |> Map.put("CURRENT_AGENT_VERSION", agent_version)
      |> Map.put("EXCLUDE_NAMESPACES", "kube-system")
      |> Map.put("REPAIR_BROKEN_POD_LABEL_KEY", "cni.istio.io/uninitialized")
      |> Map.put("REPAIR_BROKEN_POD_LABEL_VALUE", "true")
      |> Map.put("REPAIR_DELETE_PODS", "false")
      |> Map.put("REPAIR_ENABLED", "true")
      |> Map.put("REPAIR_INIT_CONTAINER_NAME", "istio-validation")
      |> Map.put("REPAIR_LABEL_PODS", "false")
      |> Map.put("REPAIR_REPAIR_PODS", "true")

    :config_map
    |> B.build_resource()
    |> B.name("istio-cni-config")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:daemon_set_istio_cni_node, battery, _state) do
    namespace = battery.config.namespace

    template =
      %{}
      |> Map.put("metadata", %{
        "annotations" => %{
          "prometheus.io/path" => "/metrics",
          "prometheus.io/port" => "15014",
          "prometheus.io/scrape" => "true"
        },
        "labels" => %{
          "battery/app" => @app_name,
          "istio.io/dataplane-mode" => "none",
          "sidecar.istio.io/inject" => "false"
        }
      })
      |> Map.put("spec", %{
        "containers" => [
          %{
            "args" => ["--log_output_level=info"],
            "command" => ["install-cni"],
            "env" => [
              %{
                "name" => "REPAIR_NODE_NAME",
                "valueFrom" => %{"fieldRef" => %{"fieldPath" => "spec.nodeName"}}
              },
              %{"name" => "REPAIR_RUN_AS_DAEMON", "value" => "true"},
              %{"name" => "REPAIR_SIDECAR_ANNOTATION", "value" => "sidecar.istio.io/status"},
              %{"name" => "ALLOW_SWITCH_TO_HOST_NS", "value" => "true"},
              %{
                "name" => "NODE_NAME",
                "valueFrom" => %{
                  "fieldRef" => %{"apiVersion" => "v1", "fieldPath" => "spec.nodeName"}
                }
              },
              %{
                "name" => "GOMEMLIMIT",
                "valueFrom" => %{"resourceFieldRef" => %{"resource" => "limits.memory"}}
              },
              %{
                "name" => "GOMAXPROCS",
                "valueFrom" => %{"resourceFieldRef" => %{"resource" => "limits.cpu"}}
              },
              %{
                "name" => "POD_NAME",
                "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.name"}}
              },
              %{
                "name" => "POD_NAMESPACE",
                "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}
              }
            ],
            "envFrom" => [%{"configMapRef" => %{"name" => "istio-cni-config"}}],
            "image" => battery.config.cni_image,
            "name" => "install-cni",
            "ports" => [%{"containerPort" => 15_014, "name" => "metrics", "protocol" => "TCP"}],
            "readinessProbe" => %{"httpGet" => %{"path" => "/readyz", "port" => 8000}},
            "resources" => %{"requests" => %{"cpu" => "100m", "memory" => "100Mi"}},
            "securityContext" => %{
              "capabilities" => %{
                "add" => ["NET_ADMIN", "NET_RAW", "SYS_PTRACE", "SYS_ADMIN", "DAC_OVERRIDE"],
                "drop" => ["ALL"]
              },
              "privileged" => false,
              "runAsGroup" => 0,
              "runAsNonRoot" => false,
              "runAsUser" => 0
            },
            "volumeMounts" => [
              %{"mountPath" => "/host/opt/cni/bin", "name" => "cni-bin-dir"},
              %{"mountPath" => "/host/proc", "name" => "cni-host-procfs", "readOnly" => true},
              %{"mountPath" => "/host/etc/cni/net.d", "name" => "cni-net-dir"},
              %{"mountPath" => "/var/run/istio-cni", "name" => "cni-socket-dir"},
              %{
                "mountPath" => "/host/var/run/netns",
                "mountPropagation" => "HostToContainer",
                "name" => "cni-netns-dir"
              },
              %{"mountPath" => "/var/run/ztunnel", "name" => "cni-ztunnel-sock-dir"}
            ]
          }
        ],
        "nodeSelector" => %{"kubernetes.io/os" => "linux"},
        "priorityClassName" => "system-node-critical",
        "serviceAccountName" => "istio-cni",
        "terminationGracePeriodSeconds" => 5,
        "tolerations" => [
          %{"effect" => "NoSchedule", "operator" => "Exists"},
          %{"key" => "CriticalAddonsOnly", "operator" => "Exists"},
          %{"effect" => "NoExecute", "operator" => "Exists"}
        ],
        "volumes" => [
          %{"hostPath" => %{"path" => "/opt/cni/bin"}, "name" => "cni-bin-dir"},
          %{
            "hostPath" => %{"path" => "/proc", "type" => "Directory"},
            "name" => "cni-host-procfs"
          },
          %{
            "hostPath" => %{"path" => "/var/run/ztunnel", "type" => "DirectoryOrCreate"},
            "name" => "cni-ztunnel-sock-dir"
          },
          %{"hostPath" => %{"path" => "/etc/cni/net.d"}, "name" => "cni-net-dir"},
          %{"hostPath" => %{"path" => "/var/run/istio-cni"}, "name" => "cni-socket-dir"},
          %{
            "hostPath" => %{"path" => "/var/run/netns", "type" => "DirectoryOrCreate"},
            "name" => "cni-netns-dir"
          }
        ]
      })
      |> B.app_labels(@app_name)
      |> B.add_owner(battery)

    spec =
      %{}
      |> Map.put("selector", %{"matchLabels" => %{"battery/app" => @app_name}})
      |> Map.put("updateStrategy", %{
        "rollingUpdate" => %{"maxUnavailable" => 1},
        "type" => "RollingUpdate"
      })
      |> B.template(template)

    :daemon_set
    |> B.build_resource()
    |> B.name("istio-cni-node")
    |> B.namespace(namespace)
    |> B.label("istio.io/rev", "default")
    |> B.spec(spec)
  end

  resource(:service_account_istio_cni, battery, _state) do
    namespace = battery.config.namespace

    :service_account
    |> B.build_resource()
    |> B.name("istio-cni")
    |> B.namespace(namespace)
    |> B.label("istio.io/rev", "default")
  end
end
