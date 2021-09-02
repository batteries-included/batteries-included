defmodule KubeResources.MLIngress do
  alias ControlServer.Notebooks

  def paths(_config) do
    Enum.map(Notebooks.list_jupyter_lab_notebooks(), &notebook_path/1)
  end

  def url(notebook_name) do
    "/x/notebooks/#{notebook_name}"
  end

  defp notebook_path(notebook) do
    %{
      "path" => url(notebook.name),
      "pathType" => "Prefix",
      "backend" => %{
        "service" => %{
          "name" => "notebook-#{notebook.name}",
          "port" => %{"number" => 8888}
        }
      }
    }
  end
end
