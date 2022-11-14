defmodule KubeResources.Notebooks do
  import KubeExt.SystemState.Namespaces

  alias KubeExt.Builder, as: B
  alias KubeExt.KubeState.Hosts
  alias KubeResources.IstioConfig.HttpRoute
  alias KubeResources.IstioConfig.VirtualService

  @app_name "notebooks"
  @url_base "/x/notebooks/"

  def virtual_service(_battery, state) do
    namespace = ml_namespace(state)
    build_virtual_service(state.notebooks, namespace)
  end

  def view_url(%{} = notebook), do: view_url(KubeExt.cluster_type(), notebook)

  def view_url(:dev, %{} = notebook), do: url(notebook)

  def view_url(_, %{} = notebook), do: "/services/ml/notebooks/#{notebook.id}"

  def url(%{} = notebook),
    do: "http://#{Hosts.control_host()}#{base_url(notebook)}"

  def base_url(%{} = notebook), do: "#{@url_base}#{notebook.name}"

  defp build_virtual_service([_ | _] = notebooks, namespace) do
    routes = Enum.map(notebooks, &notebook_http_route/1)

    B.build_resource(:istio_virtual_service)
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.name("notebooks")
    |> B.spec(VirtualService.new(http: routes))
  end

  defp build_virtual_service([] = _notebooks, _namespace) do
    nil
  end

  def notebook_http_route(%{} = notebook) do
    HttpRoute.prefix(base_url(notebook), service_name(notebook))
  end

  def materialize(battery, state) do
    state.notebooks
    |> Enum.with_index()
    |> Enum.flat_map(fn {notebook, idx} ->
      [
        {stateful_set_path(notebook, idx), stateful_set(notebook, battery, state)},
        {service_path(notebook, idx), service(notebook, battery, state)}
      ]
    end)
    |> Map.new()
    |> Map.put("/service_account", service_account(battery, state))
  end

  defp service_path(%{id: id}, _idx), do: "/notebooks/#{id}/service"
  defp service_path(_, idx), do: "/notebooks/#{idx}/idx/service"

  defp stateful_set_path(%{id: id}, _idx), do: "/notebooks/#{id}/stateful_set"
  defp stateful_set_path(_, idx), do: "/notebooks/#{idx}/idx/stateful_set"

  defp service_account(_battery, state) do
    namespace = ml_namespace(state)

    B.build_resource(:service_account)
    |> B.name("battery-notebooks")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
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
end
