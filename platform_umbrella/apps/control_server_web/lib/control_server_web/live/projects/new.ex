defmodule ControlServerWeb.Projects.NewLive do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias CommonCore.Projects.Project
  alias ControlServer.Projects

  def mount(_params, _session, socket) do
    changeset = Projects.change_project(%Project{})

    {:ok,
     socket
     |> assign(:page_title, "Start Your Project")
     |> assign(:form, to_form(changeset))}
  end

  def handle_event("validate", %{"project" => project_params}, socket) do
    changeset =
      %Project{}
      |> Projects.change_project(project_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"project" => project_params}, socket) do
    case Projects.create_project(project_params) do
      {:ok, project} ->
        {:noreply,
         socket
         |> put_flash(:info, "Project created successfully")
         |> push_navigate(to: ~p"/projects/#{project}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def render(assigns) do
    ~H"""
    <.form
      for={@form}
      phx-change="validate"
      phx-submit="save"
      class="flex flex-col h-full gap-8"
      novalidate
    >
      <div>
        <.page_header title={@page_title} back_link={~p"/projects"} />
        <.progress variant="stepped" current={1} total={2} />
      </div>

      <div class="grid lg:grid-cols-[2fr,1fr] content-start gap-6 flex-1">
        <div class="auto-rows-min row-start-2 lg:row-start-1">
          <.panel title="Tell More About Your Project">
            <div class="grid lg:grid-cols-1 xl:grid-cols-2 gap-6">
              <.input field={@form[:name]} label="Project Name" placeholder="Enter project name" />

              <.input
                field={@form[:type]}
                type="select"
                label="Project Type"
                placeholder="Select project type"
                options={Project.type_options_for_select()}
              />

              <div class="xl:col-span-2">
                <.input
                  field={@form[:description]}
                  type="textarea"
                  label="Project Description"
                  placeholder="Enter a project description (optional)"
                  maxlength={1000}
                />
              </div>
            </div>
          </.panel>
        </div>

        <div class="auto-rows-min">
          <.panel title="Info">
            <p>A place for introductory information about this stage of project creation</p>
          </.panel>
        </div>
      </div>

      <div class="flex items-center justify-end gap-4">
        <.button variant="secondary" icon={:play_circle}>View Demo Video</.button>
        <.button variant="primary" type="submit" phx-disable-with="Saving...">Next</.button>
      </div>
    </.form>
    """
  end
end
