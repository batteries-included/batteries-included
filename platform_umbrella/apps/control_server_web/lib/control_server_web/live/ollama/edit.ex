defmodule ControlServerWeb.Live.OllamaModelInstanceEdit do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias ControlServer.Ollama
  alias ControlServerWeb.Live.OllamaFormComponent

  def mount(%{"id" => id}, _session, socket) do
    model_instance = Ollama.get_model_instance!(id, preload: [:project])

    {:ok,
     socket
     |> assign(:current_page, :ai)
     |> assign(:page_title, "Edit Ollama Model")
     |> assign(:model_instance, model_instance)}
  end

  def render(assigns) do
    ~H"""
    <.live_component
      module={OllamaFormComponent}
      model_instance={@model_instance}
      id="model_instances-form"
      action={:edit}
      title="Edit Ollama Model"
    />
    """
  end
end
