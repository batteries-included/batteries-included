defmodule CommonCore.Resources.Notebooks do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "jupyter-notebooks"

  import CommonCore.StateSummary.Hosts
  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Containers.EnvValue
  alias CommonCore.OpenAPI.IstioVirtualService.VirtualService
  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.Resources.ProxyUtils, as: PU
  alias CommonCore.Resources.VirtualServiceBuilder, as: V

  @container_port 8888

  resource(:service_account, _battery, state) do
    namespace = ai_namespace(state)

    :service_account
    |> B.build_resource()
    |> B.name("battery-notebooks")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
  end

  resource(:virtual_service, battery, state) do
    namespace = ai_namespace(state)
    hosts = notebooks_hosts(state)

    virtual_service =
      state.notebooks
      |> Enum.reduce(VirtualService.new!(hosts: hosts), fn nb, vs ->
        V.prefix(vs, base_url(nb), service_name(nb), @container_port)
      end)
      |> V.prefix(PU.prefix(battery), PU.fully_qualified_service_name(battery, state), PU.port(battery))

    :istio_virtual_service
    |> B.build_resource()
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.name("notebooks")
    |> B.spec(virtual_service)
    |> F.require_battery(state, :istio_gateway)
    |> F.require_non_empty(state.notebooks)
  end

  # we can share a single configmap for now as none of the settings are configurable 
  # or would be different between notebooks and it's super easy to change when needed
  resource(:override_configmap, _battery, state) do
    name = "#{@app_name}-settings-override"
    namespace = ai_namespace(state)

    data = %{
      "overrides.json" =>
        Jason.encode!(%{
          "@jupyterlab/apputils-extension:notification" => %{
            "checkForUpdates" => false,
            # this isn't boolean, there are multiple options, "false" i.e. off is what we want
            "fetchNews" => "false"
          },
          "@jupyterlab/mainmenu-extension:plugin" => %{
            "menus" => [
              %{
                "id" => "jp-mainmenu-file",
                "items" => [
                  %{
                    "command" => "filemenu:logout",
                    "disabled" => true
                  },
                  %{
                    "command" => "filemenu:shutdown",
                    "disabled" => true
                  }
                ]
              }
            ]
          }
        })
    }

    :config_map
    |> B.build_resource()
    |> B.name(name)
    |> B.namespace(namespace)
    |> B.data(data)
  end

  multi_resource(:stateful_sets, battery, state) do
    Enum.map(state.notebooks, fn notebook -> stateful_set(notebook, battery, state) end)
  end

  multi_resource(:services, battery, state) do
    Enum.map(state.notebooks, fn notebook -> service(notebook, battery, state) end)
  end

  defp stateful_set(%{} = notebook, _battery, state) do
    namespace = ai_namespace(state)

    env = [%{"name" => "JUPYTER_ENABLE_LAB", "value" => "yes"}] ++ to_env_vars(notebook)

    template =
      %{
        "spec" => %{
          "containers" => [
            %{
              "name" => "notebook",
              "image" => notebook.image,
              "env" => env,
              "command" => ["start-notebook.sh"],
              "args" => [
                "--NotebookApp.base_url='#{base_url(notebook)}'",
                "--NotebookApp.token=''",
                "--NotebookApp.allow_password_change=False",
                "--NotebookApp.password=''"
              ],
              "ports" => [
                %{"containerPort" => @container_port, "name" => "http"}
              ],
              "volumeMounts" => [%{"mountPath" => "/opt/conda/share/jupyter/lab/settings/", "name" => "settings"}]
            }
          ],
          "volumes" => [
            %{"configMap" => %{"name" => "#{@app_name}-settings-override", "optional" => false}, "name" => "settings"}
          ]
        }
      }
      |> maybe_add_gpu_resource(notebook)
      |> maybe_add_node_selector(notebook)
      |> maybe_add_tolerations(notebook)
      |> B.app_labels(notebook.name)
      |> B.component_labels(notebook.name)
      |> B.label("battery/notebook", notebook.name)
      |> B.label("battery/managed", "true")
      |> B.add_owner(notebook)

    spec =
      %{}
      |> B.match_labels_selector(notebook.name)
      |> B.template(template)

    :stateful_set
    |> B.build_resource()
    |> B.name("notebook-#{notebook.name}")
    |> B.namespace(namespace)
    |> B.component_labels(notebook.name)
    |> B.label("battery/notebook", notebook.name)
    |> B.spec(spec)
    |> B.add_owner(notebook)
  end

  defp maybe_add_gpu_resource(resource, %{node_type: type} = _notebook)
       when type in [:any_nvidia, :nvidia_a10, :nvidia_a100, :nvidia_h100, :nvidia_h200],
       do: put_in(resource, ["spec", "containers", Access.all(), "resources"], %{"limits" => %{"nvidia.com/gpu" => 1}})

  defp maybe_add_gpu_resource(resource, _notebook), do: resource

  defp maybe_add_node_selector(resource, %{node_type: :any_nvidia} = _notebook),
    do: put_in(resource, ["spec", "nodeSelector"], %{"karpenter.sh/nodepool" => "nvidia-gpu"})

  defp maybe_add_node_selector(resource, %{node_type: :nvidia_a10} = _notebook),
    do: put_in(resource, ["spec", "nodeSelector"], %{"karpenter.sh/nodepool" => "nvidia-a10-gpu"})

  defp maybe_add_node_selector(resource, %{node_type: :nvidia_a100} = _notebook),
    do: put_in(resource, ["spec", "nodeSelector"], %{"karpenter.sh/nodepool" => "nvidia-a100-gpu"})

  defp maybe_add_node_selector(resource, %{node_type: :nvidia_h100} = _notebook),
    do: put_in(resource, ["spec", "nodeSelector"], %{"karpenter.sh/nodepool" => "nvidia-h100-gpu"})

  defp maybe_add_node_selector(resource, %{node_type: :nvidia_h200} = _notebook),
    do: put_in(resource, ["spec", "nodeSelector"], %{"karpenter.sh/nodepool" => "nvidia-h200-gpu"})

  defp maybe_add_node_selector(resource, _notebook), do: resource

  defp maybe_add_tolerations(resource, %{node_type: type} = _notebook)
       when type in [:any_nvidia, :nvidia_a10, :nvidia_a100, :nvidia_h100, :nvidia_h200],
       do: put_in(resource, ["spec", "tolerations"], [%{"key" => "nvidia.com/gpu", "operator" => "Exists"}])

  defp maybe_add_tolerations(resource, _notebook), do: resource

  defp service(notebook, _battery, state) do
    namespace = ai_namespace(state)

    spec =
      %{}
      |> B.short_selector(notebook.name)
      |> B.ports([%{name: "http", port: @container_port, targetPort: @container_port}])

    :service
    |> B.build_resource()
    |> B.name(service_name(notebook))
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.add_owner(notebook)
    |> B.spec(spec)
  end

  def service_name(notebook), do: "notebook-#{notebook.name}"

  def base_url(notebook), do: "/#{notebook.name}"

  resource(:istio_request_auth, _battery, state) do
    namespace = ai_namespace(state)

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
    namespace = ai_namespace(state)

    spec =
      state
      |> notebooks_host()
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

  defp to_env_vars(%{env_values: evs}), do: Enum.map(evs, &EnvValue.to_k8s_value/1)
  defp to_env_vars(_), do: []
end
