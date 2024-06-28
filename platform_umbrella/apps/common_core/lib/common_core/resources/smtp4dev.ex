defmodule CommonCore.Resources.Smtp4Dev do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "smtp4dev"

  import CommonCore.StateSummary.Hosts
  import CommonCore.StateSummary.Namespaces

  alias CommonCore.OpenAPI.IstioVirtualService.VirtualService
  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.Resources.ProxyUtils, as: PU
  alias CommonCore.Resources.VirtualServiceBuilder, as: V

  @http_port 80
  @smtp_port 25

  resource(:virtual_service, battery, state) do
    namespace = core_namespace(state)

    spec =
      [hosts: [smtp4dev_host(state)]]
      |> VirtualService.new!()
      |> V.prefix(PU.prefix(battery), PU.service_name(battery), PU.port(battery))
      |> V.fallback("smtp-four-dev", @http_port)

    :istio_virtual_service
    |> B.build_resource()
    |> B.name("smtp-four-dev")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :istio_gateway)
  end

  resource(:deployment_main, battery, state) do
    namespace = core_namespace(state)

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
                "image" => battery.config.image,
                "imagePullPolicy" => "IfNotPresent",
                "env" => [
                  %{
                    "name" => "ServerOptions__HostName",
                    "value" => "smtp-four-dev"
                  }
                ],
                "livenessProbe" => %{
                  "initialDelaySeconds" => 10,
                  "tcpSocket" => %{"port" => @smtp_port},
                  "timeoutSeconds" => 1
                },
                "name" => @app_name,
                "ports" => [
                  %{"containerPort" => @http_port, "name" => "http", "protocol" => "TCP"},
                  %{"containerPort" => @smtp_port, "name" => "tcp-smtp", "protocol" => "TCP"}
                ],
                "readinessProbe" => %{"tcpSocket" => %{"port" => @smtp_port}}
              }
            ],
            "serviceAccountName" => @app_name
          }
        }
      )

    :deployment
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:service_account_main, _battery, state) do
    namespace = core_namespace(state)

    :service_account
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
  end

  resource(:service_main, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{
          "name" => "tcp-smtp",
          "port" => @smtp_port,
          "protocol" => "TCP",
          "targetPort" => "tcp-smtp"
        },
        %{"name" => "http", "port" => @http_port, "protocol" => "TCP", "targetPort" => "http"}
      ])
      |> Map.put("selector", %{"battery/app" => @app_name})

    :service
    |> B.build_resource()
    |> B.name("smtp-four-dev")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:istio_request_auth, _battery, state) do
    namespace = core_namespace(state)

    # Generate the CRD's neccessary for istio to
    # validate the open id exists
    spec =
      state
      |> PU.request_auth()
      |> B.match_labels_selector(@app_name)

    :istio_request_auth
    |> B.build_resource()
    |> B.name("#{@app_name}-keycloak-auth")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :sso)
  end

  resource(:istio_auth_policy, battery, state) do
    namespace = core_namespace(state)

    spec =
      state
      |> smtp4dev_host()
      |> List.wrap()
      |> PU.auth_policy(battery)
      |> B.match_labels_selector(@app_name)

    :istio_auth_policy
    |> B.build_resource()
    |> B.name("#{@app_name}-require-keycloak-auth")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :sso)
  end
end
