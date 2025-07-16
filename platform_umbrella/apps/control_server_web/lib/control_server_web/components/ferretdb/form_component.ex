defmodule ControlServerWeb.FerretDBFormComponent do
  @moduledoc false
  use ControlServerWeb, :live_component

  import ControlServerWeb.FerretDBFormSubcomponents

  alias CommonCore.FerretDB.FerretService
  alias ControlServer.FerretDB
  alias ControlServer.Postgres
  alias Ecto.Changeset

  @impl Phoenix.LiveComponent
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div>
      <.form
        for={@form}
        id="ferret_service-form"
        phx-change="validate"
        phx-submit="save"
        phx-target={@myself}
      >
        <.page_header title={@title} back_link={~p"/ferretdb"}>
          <.button variant="dark" type="submit" phx-disable-with="Saving…">
            Save FerretDB Service
          </.button>
        </.page_header>

        <.grid columns={[sm: 1, lg: 2]}>
          <.panel class="col-span-2">
            <.size_form form={@form} pg_clusters={@pg_clusters} />

            <.flex class="justify-between w-full py-3 border-t border-gray-lighter dark:border-gray-darker" />

            <.grid columns={[sm: 1, lg: 2]} class="items-center">
              <.h5>Number of instances</.h5>
              <.input field={@form[:instances]} type="range" min="1" max="3" step="1" />
            </.grid>
          </.panel>

          <.panel title="Advanced Settings" variant="gray">
            <.flex column>
              <.input
                field={@form[:project_id]}
                type="select"
                label="Project"
                placeholder="No Project"
                placeholder_selectable={true}
                options={Enum.map(@projects, &{&1.name, &1.id})}
              />
            </.flex>
          </.panel>
        </.grid>
      </.form>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def update(%{ferret_service: ferret_service} = assigns, socket) do
    project_id = Map.get(ferret_service, :project_id) || assigns[:project_id]
    changeset = FerretDB.change_ferret_service(ferret_service, %{project_id: project_id})

    {:ok,
     socket
     |> assign(assigns)
     |> assign_changeset(changeset)
     |> assign_posssible_clusters()
     |> assign_projects()}
  end

  defp assign_changeset(socket, changeset) do
    assign(socket, changeset: changeset, form: to_form(changeset))
  end

  defp assign_posssible_clusters(socket) do
    clusters = Postgres.normal_clusters()
    assign(socket, pg_clusters: clusters)
  end

  defp assign_projects(socket) do
    projects = ControlServer.Projects.list_projects()
    assign(socket, projects: projects)
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"ferret_service" => ferret_service_params}, socket) do
    changeset =
      socket.assigns.ferret_service
      |> FerretDB.change_ferret_service(maybe_add_sizes(ferret_service_params, socket.assigns.changeset))
      |> Map.put(:action, :validate)

    {:noreply, assign_changeset(socket, changeset)}
  end

  def handle_event("save", %{"ferret_service" => ferret_service_params}, socket) do
    save_ferret_service(socket, socket.assigns.action, ferret_service_params)
  end

  defp maybe_add_sizes(%{"virtual_size" => "custom"} = params, changeset) do
    old_vert_size = Changeset.get_field(changeset, :virtual_size)

    if old_vert_size != "custom" && old_vert_size != nil do
      old_vert_size
      |> FerretService.preset_by_name()
      |> Enum.reject(fn {k, _} -> k == :name || k == "name" end)
      |> Enum.reduce(params, fn {k, v}, acc -> Map.put(acc, Atom.to_string(k), v) end)
    else
      params
    end
  end

  defp maybe_add_sizes(params, _old_service), do: params

  defp save_ferret_service(socket, :edit, ferret_service_params) do
    case FerretDB.update_ferret_service(socket.assigns.ferret_service, ferret_service_params) do
      {:ok, ferret_service} ->
        {:noreply,
         socket
         |> put_flash(:global_success, "Ferret service updated successfully")
         |> push_navigate(to: ~p"/ferretdb/#{ferret_service.id}/show")}

      {:error, %Changeset{} = changeset} ->
        {:noreply, assign_changeset(socket, changeset)}
    end
  end

  defp save_ferret_service(socket, :new, ferret_service_params) do
    case FerretDB.create_ferret_service(ferret_service_params) do
      {:ok, ferret_service} ->
        {:noreply,
         socket
         |> put_flash(:global_success, "Ferret service created successfully")
         |> push_navigate(to: ~p"/ferretdb/#{ferret_service.id}/show")}

      {:error, %Changeset{} = changeset} ->
        {:noreply, assign_changeset(socket, changeset)}
    end
  end
end
