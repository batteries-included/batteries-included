defmodule ControlServerWeb.Live.OllamaModelInstancesIndex do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.ModelInstancesTable

  alias ControlServer.Ollama

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:current_page, :ai)
     |> assign(:page_title, "Ollama Model Instances")}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _session, socket) do
    with {:ok, {model_instance, meta}} <- Ollama.list_model_instances(params) do
      {:noreply,
       socket
       |> assign(:meta, meta)
       |> assign(:model_instance, model_instance)
       |> assign(:form, to_form(meta))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("search", params, socket) do
    params = Map.delete(params, "_target")
    {:noreply, push_patch(socket, to: ~p"/model_instances?#{params}")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_link={~p"/ai"}>
      <.button variant="dark" icon={:plus} link={~p"/model_instances/new"}>
        New Model
      </.button>
    </.page_header>

    <.panel title="All Model Instances">
      <:menu>
        <.table_search
          meta={@meta}
          fields={[name: [op: :ilike]]}
          placeholder="Filter by name"
          on_change="search"
        />
      </:menu>

      <.model_instances_table rows={@model_instance} meta={@meta} />
    </.panel>
    """
  end
end
