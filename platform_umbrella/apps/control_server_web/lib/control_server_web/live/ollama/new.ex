defmodule ControlServerWeb.Live.OllamaModelInstanceNew do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias CommonCore.Ollama.ModelInstance
  alias ControlServerWeb.Live.OllamaFormComponent
  alias KubeServices.SmartBuilder

  def mount(params, _session, socket) do
    model_instance_params = SmartBuilder.new_model_instance_params()
    model_instance = Map.merge(%ModelInstance{}, model_instance_params)

    {:ok,
     socket
     |> assign(:current_page, :ai)
     |> assign(:page_title, "New Ollama Model")
     |> assign(:project_id, params["project_id"])
     |> assign(:model_instance, model_instance)}
  end

  def render(assigns) do
    ~H"""
    <.live_component
      module={OllamaFormComponent}
      model_instance={@model_instance}
      id="model_instance-form"
      action={:new}
      title="New Ollama Model"
      project_id={@project_id}
    />
    """
  end
end
