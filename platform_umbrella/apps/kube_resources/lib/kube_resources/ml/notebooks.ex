defmodule KubeResources.Notebooks do
  use KubeResources.ResourceGenerator, app_name: "juypter-notebooks"

  import CommonCore.StateSummary.Namespaces
  import CommonCore.StateSummary.Hosts

  alias KubeResources.Builder, as: B
  alias KubeResources.FilterResource, as: F
  alias KubeResources.IstioConfig.HttpRoute
  alias KubeResources.IstioConfig.VirtualService

  def notebook_http_route(%{} = notebook) do
    HttpRoute.prefix(base_url(notebook), service_name(notebook))
  end

  resource(:service_account, _battery, state) do
    namespace = ml_namespace(state)

    B.build_resource(:service_account)
    |> B.name("battery-notebooks")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
  end

  resource(:virtual_service, _battery, state) do
    namespace = ml_namespace(state)
    routes = Enum.map(state.notebooks, &notebook_http_route/1)

    B.build_resource(:istio_virtual_service)
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.name("notebooks")
    |> B.spec(VirtualService.new(http: routes, hosts: [notebooks_host(state)]))
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
    owner_id = Map.get(notebook, :id, "bootstrapped")

    template =
      %{}
      |> B.app_labels(@app_name)
      |> B.label("battery/notebook", notebook.name)
      |> B.owner_label(owner_id)
      |> B.spec(%{
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
              %{"containerPort" => 8888, "name" => "http"}
            ]
          }
        ]
      })

    spec =
      %{}
      |> B.match_labels_selector(@app_name)
      |> B.template(template)

    B.build_resource(:stateful_set)
    |> B.name("notebook-#{notebook.name}")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.label("battery/notebook", notebook.name)
    |> B.spec(spec)
    |> B.owner_label(owner_id)
  end

  defp service(notebook, _battery, state) do
    namespace = ml_namespace(state)
    owner_id = Map.get(notebook, :id, "bootstrapped")

    spec =
      %{}
      |> B.short_selector("battery/notebook", notebook.name)
      |> B.ports([%{name: "http", port: 8888, targetPort: 8888}])

    B.build_resource(:service)
    |> B.name(service_name(notebook))
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.owner_label(owner_id)
    |> B.spec(spec)
  end

  def service_name(notebook), do: "notebook-#{notebook.name}"

  def base_url(notebook), do: "/#{notebook.name}"
end
