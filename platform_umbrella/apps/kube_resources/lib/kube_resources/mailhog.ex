defmodule KubeResources.Mailhog do
  use KubeExt.ResourceGenerator, app_name: "mailhog"

  import CommonCore.SystemState.Namespaces
  import CommonCore.SystemState.Hosts

  alias KubeResources.IstioConfig.VirtualService
  alias KubeExt.Builder, as: B
  alias KubeExt.FilterResource, as: F

  resource(:virtual_service, _battery, state) do
    namespace = base_namespace(state)

    spec = VirtualService.fallback("mailhog-http", hosts: [mailhog_host(state)])

    B.build_resource(:istio_virtual_service)
    |> B.name("mailhog")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :istio_gateway)
  end

  resource(:deployment_main, battery, state) do
    namespace = base_namespace(state)

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"battery/app" => @app_name}}
      )
      |> Map.put(
        "template",
        %{
          "metadata" => %{
            "labels" => %{
              "battery/app" => @app_name,
              "battery/managed" => "true"
            }
          },
          "spec" => %{
            "automountServiceAccountToken" => false,
            "containers" => [
              %{
                "env" => [
                  %{
                    "name" => "MH_HOSTNAME",
                    "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.name"}}
                  }
                ],
                "image" => battery.config.image,
                "imagePullPolicy" => "IfNotPresent",
                "livenessProbe" => %{
                  "initialDelaySeconds" => 10,
                  "tcpSocket" => %{"port" => 1025},
                  "timeoutSeconds" => 1
                },
                "name" => "mailhog",
                "ports" => [
                  %{"containerPort" => 8025, "name" => "http", "protocol" => "TCP"},
                  %{"containerPort" => 1025, "name" => "tcp-smtp", "protocol" => "TCP"}
                ],
                "readinessProbe" => %{"tcpSocket" => %{"port" => 1025}},
                "resources" => %{},
                "securityContext" => %{
                  "allowPrivilegeEscalation" => false,
                  "capabilities" => %{"drop" => ["ALL"]},
                  "privileged" => false,
                  "readOnlyRootFilesystem" => true
                }
              }
            ],
            "securityContext" => %{
              "fsGroup" => 1000,
              "runAsGroup" => 1000,
              "runAsNonRoot" => true,
              "runAsUser" => 1000
            },
            "serviceAccountName" => "mailhog"
          }
        }
      )

    B.build_resource(:deployment)
    |> B.name("mailhog")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:service_account_main, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:service_account)
    |> Map.put("imagePullSecrets", [])
    |> B.name("mailhog")
    |> B.namespace(namespace)
  end

  resource(:service_main, _battery, state) do
    namespace = base_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "tcp-smtp", "port" => 1025, "protocol" => "TCP", "targetPort" => "tcp-smtp"}
      ])
      |> Map.put("selector", %{"battery/app" => @app_name})

    B.build_resource(:service)
    |> B.name("mailhog")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:service_http, _battery, state) do
    namespace = base_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "http", "port" => 8025, "protocol" => "TCP", "targetPort" => "http"}
      ])
      |> Map.put("selector", %{"battery/app" => @app_name})

    B.build_resource(:service)
    |> B.name("mailhog-http")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end
end
