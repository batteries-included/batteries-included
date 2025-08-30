defmodule ControlServerWeb.Projects.ProjectForm do
  @moduledoc false
  use ControlServerWeb, :live_component

  import ControlServerWeb.ProjectsSubcomponents

  alias CommonCore.Projects.Project
  alias ControlServer.Projects

  @default_description """
  ## Project Info

  Describe your project here. This is a great place to provide context and help others understand what you're working on.

  ## Operational Runbook (Example)

  - Start incident response documentation
  - Alert on-call rotations
  - Start shared communication
  """

  def mount(socket) do
    changeset = Projects.change_project(%Project{description: @default_description})

    {:ok,
     socket
     |> assign(:class, nil)
     |> assign(:form, to_form(changeset))}
  end

  def handle_event("validate", %{"project" => project_params}, socket) do
    changeset =
      %Project{}
      |> Projects.change_project(project_params)
      |> Map.put(:action, :validate)

    # Send project type changes to the parent live view so the steps can be updated
    if project_type = Ecto.Changeset.get_change(changeset, :type) do
      send(self(), {:project_type, project_type})
    end

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"project" => project_params}, socket) do
    project = Projects.change_project(%Project{}, project_params)

    case Ecto.Changeset.apply_action(project, :insert) do
      {:ok, _} ->
        # Don't create the project yet, just send the data to the parent component
        send(self(), {:next, {__MODULE__, project_params}})

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def get_name_for_resource(%{data: %{__MODULE__ => %{"name" => project_name}}}) do
    project_name
    |> String.replace(~r/\s+/, "-")
    |> String.replace(~r/[^a-zA-Z0-9_-]/, "")
  end

  def get_name_for_resource(_), do: nil

  def render(assigns) do
    ~H"""
    <div class="contents">
      <.form
        id={@id}
        for={@form}
        class={@class}
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.subform
          flash={@flash}
          title="Tell More About Your Project"
          description={@form[:description].value}
        >
          <.fieldset responsive>
            <.field>
              <:label>Project Name</:label>
              <.input field={@form[:name]} placeholder="Enter project name" />
            </.field>

            <.field>
              <:label help="Determines which types of resources to create and batteries to enable. AI projects create a Jupyter notebook, Web projects create a Knative/Traditional Service, and most projects can include a database. Bare projects don't create any resources.">
                Project Type
              </:label>
              <.input
                type="select"
                field={@form[:type]}
                placeholder="Select project type"
                options={Project.type_options()}
              />
            </.field>
          </.fieldset>

          <.field>
            <:label>Project Description</:label>
            <.input
              type="textarea"
              field={@form[:description]}
              placeholder="Enter a project description (optional)"
              maxlength={1000}
              rows="15"
            />
          </.field>
        </.subform>
      </.form>
    </div>
    """
  end
end
