defmodule CommonCore.Resources.Istio.Ztunnel do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "istio-ztunnel"

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.Istio.IstioConfigMapGenerator

  resource(:daemon_set_ztunnel, battery, _state) do
    namespace = battery.config.namespace

    template =
      %{}
      |> Map.put("metadata", %{
        "annotations" => %{
          "prometheus.io/port" => "15020",
          "prometheus.io/scrape" => "true",
          "sidecar.istio.io/inject" => "false"
        },
        "labels" => %{
          "istio.io/dataplane-mode" => "none",
          "sidecar.istio.io/inject" => "false"
        }
      })
      |> Map.put("spec", %{
        "containers" => [
          %{
            "args" => ["proxy", "ztunnel"],
            "env" => [
              %{"name" => "CA_ADDRESS", "value" => IstioConfigMapGenerator.discovery_address(battery)},
              %{"name" => "XDS_ADDRESS", "value" => IstioConfigMapGenerator.discovery_address(battery)},
              %{"name" => "RUST_LOG", "value" => "info"},
              %{"name" => "RUST_BACKTRACE", "value" => "1"},
              %{"name" => "ISTIO_META_CLUSTER_ID", "value" => "Kubernetes"},
              %{"name" => "INPOD_ENABLED", "value" => "true"},
              %{"name" => "TERMINATION_GRACE_PERIOD_SECONDS", "value" => "30"},
              %{
                "name" => "POD_NAME",
                "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.name"}}
              },
              %{
                "name" => "POD_NAMESPACE",
                "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}
              },
              %{
                "name" => "NODE_NAME",
                "valueFrom" => %{"fieldRef" => %{"fieldPath" => "spec.nodeName"}}
              },
              %{
                "name" => "INSTANCE_IP",
                "valueFrom" => %{"fieldRef" => %{"fieldPath" => "status.podIP"}}
              },
              %{
                "name" => "SERVICE_ACCOUNT",
                "valueFrom" => %{"fieldRef" => %{"fieldPath" => "spec.serviceAccountName"}}
              },
              %{"name" => "ISTIO_META_ENABLE_HBONE", "value" => "true"}
            ],
            "image" => battery.config.ztunnel_image,
            "name" => "istio-proxy",
            "ports" => [
              %{"containerPort" => 15_020, "name" => "ztunnel-stats", "protocol" => "TCP"}
            ],
            "readinessProbe" => %{"httpGet" => %{"path" => "/healthz/ready", "port" => 15_021}},
            "resources" => %{"requests" => %{"cpu" => "200m", "memory" => "512Mi"}},
            "securityContext" => %{
              "allowPrivilegeEscalation" => true,
              "capabilities" => %{
                "add" => ["NET_ADMIN", "SYS_ADMIN", "NET_RAW"],
                "drop" => ["ALL"]
              },
              "privileged" => false,
              "readOnlyRootFilesystem" => true,
              "runAsGroup" => 1337,
              "runAsNonRoot" => false,
              "runAsUser" => 0
            },
            "volumeMounts" => [
              %{"mountPath" => "/var/run/secrets/istio", "name" => "istiod-ca-cert"},
              %{"mountPath" => "/var/run/secrets/tokens", "name" => "istio-token"},
              %{"mountPath" => "/var/run/ztunnel", "name" => "cni-ztunnel-sock-dir"},
              %{"mountPath" => "/tmp", "name" => "tmp"}
            ]
          }
        ],
        "nodeSelector" => %{"kubernetes.io/os" => "linux"},
        "priorityClassName" => "system-node-critical",
        "serviceAccountName" => "ztunnel",
        "terminationGracePeriodSeconds" => 30,
        "tolerations" => [
          %{"effect" => "NoSchedule", "operator" => "Exists"},
          %{"key" => "CriticalAddonsOnly", "operator" => "Exists"},
          %{"effect" => "NoExecute", "operator" => "Exists"}
        ],
        "volumes" => [
          %{
            "name" => "istio-token",
            "projected" => %{
              "sources" => [
                %{
                  "serviceAccountToken" => %{
                    "audience" => "istio-ca",
                    "expirationSeconds" => 43_200,
                    "path" => "istio-token"
                  }
                }
              ]
            }
          },
          %{"configMap" => %{"name" => "istio-ca-root-cert"}, "name" => "istiod-ca-cert"},
          %{
            "hostPath" => %{"path" => "/var/run/ztunnel", "type" => "DirectoryOrCreate"},
            "name" => "cni-ztunnel-sock-dir"
          },
          %{"emptyDir" => %{}, "name" => "tmp"}
        ]
      })
      |> B.app_labels("ztunnel")
      |> B.add_owner(battery)

    spec =
      %{}
      |> Map.put("selector", %{"matchLabels" => %{"battery/app" => "ztunnel"}})
      |> Map.put("updateStrategy", %{
        "rollingUpdate" => %{"maxSurge" => 1, "maxUnavailable" => 0},
        "type" => "RollingUpdate"
      })
      |> B.template(template)

    :daemon_set
    |> B.build_resource()
    |> B.name("ztunnel")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:service_account_ztunnel, battery, _state) do
    :service_account
    |> B.build_resource()
    |> B.name("ztunnel")
    |> B.namespace(battery.config.namespace)
  end
end
