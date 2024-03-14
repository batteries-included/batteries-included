defmodule ControlServerWeb.Live.Project.FormComponent do
  @moduledoc false
  use ControlServerWeb, :live_component

  alias ControlServer.Projects

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        for={@form}
        id="system_project-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} label="Name" />
        <.input
          field={@form[:type]}
          type="select"
          label="Type"
          placeholder="Choose a value"
          options={Ecto.Enum.values(Projects.SystemProject, :type)}
        />
        <div class="sm:col-span-2">
          <.input field={@form[:description]} type="textarea" label="Description" />
        </div>
        <:actions>
          <.button variant="primary" type="submit" phx-disable-with="Saving...">Save</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def update(%{system_project: system_project} = assigns, socket) do
    changeset = Projects.change_system_project(system_project)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, to_form(changeset))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"system_project" => system_project_params}, socket) do
    changeset =
      socket.assigns.system_project
      |> Projects.change_system_project(system_project_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
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
         |> push_navigate(to: ~p"/system_projects/#{system_project}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_system_project(socket, :new, system_project_params) do
    case Projects.create_system_project(system_project_params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "System project created successfully")
         |> push_navigate(to: ~p"/system_projects")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
