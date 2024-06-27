defmodule ControlServerWeb.Live.JupyterLabNotebookNew do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias CommonCore.Notebooks.JupyterLabNotebook
  alias ControlServerWeb.Live.Notebooks.FormComponent
  alias KubeServices.SmartBuilder

  def mount(params, _session, socket) do
    notebook_params = SmartBuilder.new_juptyer_params()
    notebook = Map.merge(%JupyterLabNotebook{}, notebook_params)

    {:ok,
     socket
     |> assign(:current_page, :ai)
     |> assign(:project_id, params["project_id"])
     |> assign(:notebook, notebook)}
  end

  def render(assigns) do
    ~H"""
    <.live_component
      module={FormComponent}
      notebook={@notebook}
      id="notebook-form"
      action={:new}
      title="New Jupyter Notebook"
      project_id={@project_id}
    />
    """
  end
end
