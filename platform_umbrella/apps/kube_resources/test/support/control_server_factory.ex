defmodule KubeResources.ControlServerFactory do
  @moduledoc """

  Factory for creating db represenetions needed in kube_resources
  """

  # with Ecto
  use ExMachina.Ecto, repo: ControlServer.Repo

  def notebook_factory do
    %ControlServer.Notebooks.JupyterLabNotebook{
      name: "test-notebook"
    }
  end
end
