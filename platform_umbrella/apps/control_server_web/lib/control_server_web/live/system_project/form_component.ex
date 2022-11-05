defmodule ControlServerWeb.Live.Project.FormComponent do
  use ControlServerWeb, :live_component

  alias ControlServer.Projects

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        :let={f}
        for={@changeset}
        id="system_project-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={{f, :name}} type="text" label="name" />
        <.input
          field={{f, :type}}
          type="select"
          label="type"
          prompt="Choose a value"
          options={Ecto.Enum.values(Projects.SystemProject, :type)}
        />
        <.input field={{f, :description}} type="textarea" label="description" />
        <:actions>
          <.button phx-disable-with="Saving...">Save System project</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{system_project: system_project} = assigns, socket) do
    changeset = Projects.change_system_project(system_project)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"system_project" => system_project_params}, socket) do
    changeset =
      socket.assigns.system_project
      |> Projects.change_system_project(system_project_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"system_project" => system_project_params}, socket) do
    save_system_project(socket, socket.assigns.action, system_project_params)
  end

  defp save_system_project(socket, :edit, system_project_params) do
    case Projects.update_system_project(socket.assigns.system_project, system_project_params) do
      {:ok, system_project} ->
        {:noreply,
         socket
         |> put_flash(:info, "System project updated successfully")
         |> push_navigate(to: ~p"/system_projects/#{system_project}/show")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_system_project(socket, :new, system_project_params) do
    case Projects.create_system_project(system_project_params) do
      {:ok, system_project} ->
        {:noreply,
         socket
         |> put_flash(:info, "System project created successfully")
         |> push_navigate(to: ~p"/system_projects/#{system_project}/show")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
