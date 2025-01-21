defmodule ControlServerWeb.Live.OllamaFormComponent do
  @moduledoc false

  use ControlServerWeb, :live_component

  import ControlServerWeb.OllamaFormSubcomponents

  alias CommonCore.Ollama.ModelInstance
  alias ControlServer.Ollama
  alias ControlServer.Projects
  alias KubeServices.SystemState.SummaryBatteries

  def mount(socket) do
    {:ok,
     socket
     |> assign_new(:namespace, fn -> SummaryBatteries.ai_namespace() end)
     |> assign_projects()}
  end

  def update(assigns, socket) do
    project_id = Map.get(assigns.model_instance, :project_id) || assigns[:project_id]
    changeset = ModelInstance.changeset(assigns.model_instance, %{project_id: project_id})

    {:ok,
     socket
     |> assign(assigns)
     |> assign_changeset(changeset)}
  end

  def handle_event("validate", %{"model_instance" => params}, socket) do
    changeset =
      socket.assigns.model_instance
      |> ModelInstance.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_changeset(socket, changeset)}
  end

  def handle_event("save", %{"model_instance" => params}, socket) do
    save_model_instance(socket, socket.assigns.action, params)
  end

  defp save_model_instance(socket, :new, params) do
    case Ollama.create_model_instance(params) do
      {:ok, model_instance} ->
        {:noreply,
         socket
         |> put_flash(:global_success, "Model successfully created")
         |> push_navigate(to: ~p"/model_instances/#{model_instance.id}/show")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_changeset(socket, changeset)}
    end
  end

  defp save_model_instance(socket, :edit, params) do
    case Ollama.update_model_instance(socket.assigns.model_instance, params) do
      {:ok, model_instance} ->
        {:noreply,
         socket
         |> put_flash(:global_success, "Model successfully updated")
         |> push_navigate(to: ~p"/model_instances/#{model_instance.id}/show")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_changeset(socket, changeset)}
    end
  end

  defp assign_projects(socket) do
    assign(socket, projects: Projects.list_projects())
  end

  defp assign_changeset(socket, changeset) do
    assign(socket,
      changeset: changeset,
      form: to_form(changeset)
    )
  end

  def render(assigns) do
    ~H"""
    <div>
      <.form
        novalidate
        id={@id}
        for={@form}
        phx-change="validate"
        phx-submit="save"
        phx-target={@myself}
      >
        <.page_header
          title={@title}
          back_link={
            if @action == :new,
              do: ~p"/model_instances",
              else: ~p"/model_instances/#{@model_instance}/show"
          }
        >
          <.button variant="dark" type="submit" phx-disable-with="Saving…">
            Save Model
          </.button>
        </.page_header>

        <.grid columns={[sm: 1, lg: 2]}>
          <.panel>
            <.model_form form={@form} action={@action} />
          </.panel>
          <.panel variant="gray">
            <.size_form form={@form} />
          </.panel>
        </.grid>
      </.form>
    </div>
    """
  end
end
