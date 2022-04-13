defmodule KubeResources.Notebooks do
  alias ControlServer.Notebooks
  alias ControlServer.Notebooks.JupyterLabNotebook
  alias KubeExt.Builder, as: B
  alias KubeResources.IstioConfig.HttpRoute
  alias KubeResources.IstioConfig.VirtualService
  alias KubeResources.MLSettings

  require Logger

  @app_name "notebooks"
  @url_base "/x/notebooks/"

  def ingress(config) do
    Enum.map(Notebooks.list_jupyter_lab_notebooks(), fn jln -> notebook_ingress(jln, config) end)
  end

  defp notebook_ingress(%Notebooks.JupyterLabNotebook{} = notebook, config) do
    Logger.debug("Creating ingress for #{inspect(notebook)}")
    namespace = MLSettings.public_namespace(config)

    B.build_resource(:ingress, url(notebook), "notebook-#{notebook.name}", "http")
    |> B.name("notebook-#{notebook.name}")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
  end

  def virtual_service(config) do
    namespace = MLSettings.public_namespace(config)
    notebooks = Notebooks.list_jupyter_lab_notebooks()
    build_virtual_service(namespace, notebooks)
  end

  def view_url(%JupyterLabNotebook{} = notebook), do: view_url(KubeExt.cluster_type(), notebook)

  def view_url(:dev, %JupyterLabNotebook{} = notebook), do: url(notebook)

  def view_url(_, %JupyterLabNotebook{} = notebook), do: "/services/ml/notebooks/#{notebook.id}"

  def url(%JupyterLabNotebook{} = notebook),
    do: "//control.#{KubeState.IstioIngress.single_address()}.sslip.io#{base_url(notebook)}"

  def base_url(%JupyterLabNotebook{} = notebook), do: "#{@url_base}#{notebook.name}"

  defp build_virtual_service(namespace, [_ | _] = notebooks) do
    routes = Enum.map(notebooks, &notebook_http_route/1)

    B.build_resource(:virtual_service)
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.name("notebooks")
    |> B.spec(VirtualService.new(http: routes))
  end

  defp build_virtual_service(_namespace, [] = _notebooks) do
    nil
  end

  def notebook_http_route(%Notebooks.JupyterLabNotebook{} = notebook) do
    HttpRoute.prefix(base_url(notebook), service_name(notebook))
  end

  def materialize(config) do
    Notebooks.list_jupyter_lab_notebooks()
    |> Enum.flat_map(fn notebook ->
      Logger.debug("Notebook => #{inspect(notebook)}")

      [
        {"/#{notebook.id}/stateful", stateful_set(config, notebook)},
        {"/#{notebook.id}/service", service(config, notebook)}
      ]
    end)
    |> Map.new()
    |> Map.put("/service_account", service_account(config))
  end

  defp service_account(config) do
    namespace = MLSettings.public_namespace(config)

    B.build_resource(:service_account)
    |> B.name("battery-notebooks")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
  end

  defp stateful_set(config, %JupyterLabNotebook{} = notebook) do
    namespace = MLSettings.public_namespace(config)

    template =
      %{}
      |> B.app_labels(@app_name)
      |> B.label("battery/notebook", notebook.name)
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
  end

  defp service(config, notebook) do
    namespace = MLSettings.public_namespace(config)

    spec =
      %{}
      |> B.short_selector("battery/notebook", notebook.name)
      |> B.ports([%{name: "http", port: 8888, targetPort: 8888}])

    B.build_resource(:service)
    |> B.name(service_name(notebook))
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(spec)
  end

  def service_name(notebook), do: "notebook-#{notebook.name}"
end
