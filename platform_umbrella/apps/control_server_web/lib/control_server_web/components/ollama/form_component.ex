defmodule ControlServerWeb.Live.Ollama.FormComponent do
  @moduledoc false

  use ControlServerWeb, :live_component

  alias CommonCore.Ollama.ModelInstance
  alias CommonCore.Util.Memory
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
            <.grid columns={[sm: 1, lg: 2]} class="items-center">
              <.input field={@form[:name]} label="Name" />
              <.input
                field={@form[:model]}
                label="Model"
                type="select"
                placeholder="Select Model"
                options={ModelInstance.model_options_for_select()}
              />
            </.grid>
          </.panel>
          <.panel variant="gray">
            <.flex column>
              <.input
                field={@form[:virtual_size]}
                type="select"
                label="Size"
                placeholder="Choose a size"
                options={ModelInstance.preset_options_for_select()}
              />

              <.data_list
                variant="horizontal-bolded"
                data={[
                  {"Memory limits:", Memory.humanize(@form[:memory_limits].value)},
                  {"CPU Request:", @form[:cpu_requested].value}
                ]}
              />
            </.flex>
          </.panel>
        </.grid>
      </.form>
    </div>
    """
  end
end
