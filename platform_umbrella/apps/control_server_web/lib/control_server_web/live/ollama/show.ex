defmodule ControlServerWeb.Live.OllamaModelInstanceShow do
  @moduledoc false

  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias CommonCore.Util.Memory
  alias ControlServer.Ollama

  def mount(_, _session, socket) do
    {:ok,
     socket
     |> assign(:current_page, :ai)
     |> assign(:page_title, "Ollama Model Instances")}
  end

  def handle_params(%{"id" => id}, _, socket) do
    model_instance = Ollama.get_model_instance!(id, preload: [:project])
    {:noreply, assign(socket, model_instance: model_instance)}
  end

  def handle_event("delete", _params, socket) do
    case Ollama.delete_model_instance(socket.assigns.model_instance) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:global_success, "Model successfully deleted")
         |> push_navigate(to: ~p"/model_instances")}

      _ ->
        {:noreply, put_flash(socket, :global_error, "Could not delete model")}
    end
  end

  def render(assigns) do
    ~H"""
    <.page_header title={"Ollama Model: #{@model_instance.name}"} back_link={~p"/notebooks"}>
      <:menu>
        <.badge :if={@model_instance.project_id}>
          <:item label="Project" navigate={~p"/projects/#{@model_instance.project_id}"}>
            {@model_instance.project.name}
          </:item>
        </.badge>
      </:menu>

      <.flex>
        <.tooltip target_id="edit-tooltip">Edit Model</.tooltip>
        <.tooltip target_id="delete-tooltip">Delete Model</.tooltip>
        <.flex gaps="0">
          <.button id="edit-tooltip" variant="icon" icon={:pencil} link={edit_url(@model_instance)} />
          <.button
            id="delete-tooltip"
            variant="icon"
            icon={:trash}
            phx-click="delete"
            data-confirm={"Are you sure you want to delete the #{@model_instance.name} model?"}
          />
        </.flex>
      </.flex>
    </.page_header>
    <.grid columns={%{sm: 1, lg: 2}}>
      <.panel title="Details" variant="gray">
        <.data_list>
          <:item title="Model">
            {@model_instance.model}
          </:item>
          <:item title="Instances">
            {@model_instance.num_instances}
          </:item>
          <:item :if={@model_instance.memory_limits} title="Memory Limits">
            {Memory.humanize(@model_instance.memory_limits)}
          </:item>
        </.data_list>
      </.panel>
    </.grid>
    """
  end

  defp edit_url(model_instance), do: ~p"/model_instances/#{model_instance}/edit"
end
