defmodule ControlServerWeb.Live.ProjectsEdit do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias ControlServer.Projects

  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _session, socket) do
    project = Projects.get_project!(id)
    changeset = Projects.change_project(project)

    {:ok,
     socket
     |> assign(:page_title, "Edit Project")
     |> assign(:form, to_form(changeset))
     |> assign(:project, project)}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"project" => params}, socket) do
    changeset =
      socket.assigns.project
      |> Projects.change_project(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl Phoenix.LiveView
  def handle_event("save", %{"project" => params}, socket) do
    case Projects.update_project(socket.assigns.project, params) do
      {:ok, project} ->
        {:noreply,
         socket
         |> put_flash(:global_success, "Project updated successfully")
         |> push_navigate(to: ~p"/projects/#{project.id}/show")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_link={~p"/projects/#{@project.id}/show"}>
      <.button variant="dark" type="submit" form="edit-project-form" phx-disable-with="Saving…">
        Save Project
      </.button>
    </.page_header>

    <div class="grid grid-cols-1 lg:grid-cols-[2fr,1fr] gap-4">
      <.panel>
        <.simple_form for={@form} id="edit-project-form" phx-change="validate" phx-submit="save">
          <.flex column>
            <.input field={@form[:name]} label="Project Name" placeholder="Enter project name" />

            <.input
              field={@form[:description]}
              type="textarea"
              label="Project Description"
              placeholder="Enter a project description (optional)"
              maxlength={1000}
              rows="15"
            />
          </.flex>
        </.simple_form>
      </.panel>

      <.panel title="Description">
        <.markdown content={@form[:description].value} />
      </.panel>
    </div>
    """
  end
end
