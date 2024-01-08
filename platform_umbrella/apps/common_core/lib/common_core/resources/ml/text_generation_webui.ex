defmodule CommonCore.Resources.TextGenerationWebUI do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "text-generation-webui"

  import CommonCore.StateSummary.Hosts
  import CommonCore.StateSummary.Namespaces

  alias CommonCore.OpenApi.IstioVirtualService.VirtualService
  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.Resources.ProxyUtils, as: PU
  alias CommonCore.Resources.VirtualServiceBuilder, as: V

  @mount_points ~W(loras models presets prompts training)
  @http_port 7860
  @container_ports [http: @http_port, api: 5000, streaming: 5005]

  @service_name "text-generation-webui-svc"

  resource(:service_account, _battery, state) do
    namespace = core_namespace(state)

    :service_account
    |> B.build_resource()
    |> B.name("text-generation-webui")
    |> B.namespace(namespace)
  end

  resource(:deployment, battery, state) do
    namespace = core_namespace(state)

    volumes = [
      %{"emptyDir" => %{}, "name" => "text-generation-webui-pvc"}
    ]

    containers = [
      %{
        "image" => battery.config.image,
        "name" => "text-generation-webui",
        "env" => [%{"name" => "EXTRA_LAUNCH_ARGS", "value" => "--listen\ --api"}],
        "volumeMounts" =>
          Enum.map(
            @mount_points,
            fn point ->
              %{
                "mountPath" => "/app/#{point}",
                "name" => "text-generation-webui-pvc",
                "readOnly" => false,
                "subPath" => point
              }
            end
          ),
        "ports" =>
          Enum.map(@container_ports, fn {type, port} -> %{"containerPort" => port, "name" => Atom.to_string(type)} end)
      }
    ]

    template =
      %{
        "metadata" => %{
          "labels" => %{"battery/managed" => "true"}
        },
        "spec" => %{
          "containers" => containers,
          "volumes" => volumes,
          "serviceAccountName" => "text-generation-webui"
        }
      }
      |> B.app_labels(@app_name)
      |> B.add_owner(battery)

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put("selector", %{"matchLabels" => %{"battery/app" => @app_name}})
      |> B.template(template)

    :deployment
    |> B.build_resource()
    |> B.name("text-generation-webui")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:service_main, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put(
        "ports",
        Enum.map(@container_ports, fn {type, port} ->
          %{
            "name" => type,
            "port" => port,
            "protocol" => "TCP",
            "appProtocol" => "http"
          }
        end)
      )
      |> Map.put("selector", %{"battery/app" => @app_name})

    :service
    |> B.build_resource()
    |> B.name(@service_name)
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:virtual_service, battery, state) do
    namespace = core_namespace(state)

    spec =
      [hosts: [text_generation_webui_host(state)]]
      |> VirtualService.new!()
      |> V.prefix(
        PU.prefix(battery, state),
        PU.service_name(battery, state),
        PU.port(battery, state)
      )
      |> V.fallback(@service_name, @http_port)

    :istio_virtual_service
    |> B.build_resource()
    |> B.name("text-generation-webui")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :istio_gateway)
  end

  resource(:istio_request_auth, _battery, state) do
    namespace = core_namespace(state)

    # This is the standard request auth.
    # Make sure that anything coming to
    # Virtual services matching this app_name are valid
    # The auth policy below will ensure they are present as well.
    spec =
      state
      |> PU.request_auth()
      |> B.match_labels_selector(@app_name)

    :istio_request_auth
    |> B.build_resource()
    |> B.name("#{@app_name}-keycloak-auth-valid")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :sso)
  end

  resource(:istio_auth_policy, battery, state) do
    namespace = core_namespace(state)

    spec =
      state
      |> text_generation_webui_host()
      |> List.wrap()
      |> PU.auth_policy(battery, state)
      |> B.match_labels_selector(@app_name)

    :istio_auth_policy
    |> B.build_resource()
    |> B.name("#{@app_name}-require-keycloak-auth")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :sso)
  end
end
