defmodule CommonCore.Resources.Notebooks do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "jupyter-notebooks"

  import CommonCore.StateSummary.Hosts
  import CommonCore.StateSummary.Namespaces

  alias CommonCore.OpenApi.IstioVirtualService.VirtualService
  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.Resources.ProxyUtils, as: PU
  alias CommonCore.Resources.VirtualServiceBuilder, as: V

  @container_port 8888

  resource(:service_account, _battery, state) do
    namespace = ml_namespace(state)

    :service_account
    |> B.build_resource()
    |> B.name("battery-notebooks")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
  end

  resource(:virtual_service, battery, state) do
    namespace = ml_namespace(state)
    host = notebooks_host(state)

    virtual_service =
      state.notebooks
      |> Enum.reduce(VirtualService.new!(hosts: [host]), fn nb, vs ->
        V.prefix(vs, base_url(nb), service_name(nb), @container_port)
      end)
      |> V.prefix(
        PU.prefix(battery, state),
        PU.fully_qualified_service_name(battery, state),
        PU.port(battery, state)
      )

    :istio_virtual_service
    |> B.build_resource()
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.name("notebooks")
    |> B.spec(virtual_service)
    |> F.require_battery(state, :istio_gateway)
    |> F.require_non_empty(state.notebooks)
  end

  multi_resource(:stateful_sets, battery, state) do
    Enum.map(state.notebooks, fn notebook -> stateful_set(notebook, battery, state) end)
  end

  multi_resource(:services, battery, state) do
    Enum.map(state.notebooks, fn notebook -> service(notebook, battery, state) end)
  end

  defp stateful_set(%{} = notebook, _battery, state) do
    namespace = ml_namespace(state)

    template =
      %{
        "metadata" => %{"labels" => %{"battery/managed" => "true"}},
        "spec" => %{
          "containers" => [
            %{
              "name" => "notebook",
              "image" => notebook.image,
              "env" => [
                %{"name" => "JUPYTER_ENABLE_LAB", "value" => "yes"}
              ],
              "command" => ["start-notebook.sh"],
              "args" => [
                "--NotebookApp.base_url='#{base_url(notebook)}'",
                "--NotebookApp.token=''",
                "--NotebookApp.allow_password_change=False",
                "--NotebookApp.password=''"
              ],
              "ports" => [
                %{"containerPort" => @container_port, "name" => "http"}
              ]
            }
          ]
        }
      }
      |> B.app_labels(notebook.name)
      |> B.component_label(notebook.name)
      |> B.label("battery/notebook", notebook.name)
      |> B.add_owner(notebook)

    spec =
      %{}
      |> B.match_labels_selector(@app_name)
      |> B.template(template)

    :stateful_set
    |> B.build_resource()
    |> B.name("notebook-#{notebook.name}")
    |> B.namespace(namespace)
    |> B.component_label(notebook.name)
    |> B.label("battery/notebook", notebook.name)
    |> B.spec(spec)
    |> B.add_owner(notebook)
  end

  defp service(notebook, _battery, state) do
    namespace = ml_namespace(state)

    spec =
      %{}
      |> B.short_selector("battery/app", notebook.name)
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
    namespace = ml_namespace(state)

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
    namespace = ml_namespace(state)

    spec =
      state
      |> notebooks_host()
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
