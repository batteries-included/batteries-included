defmodule ControlServerWeb.Live.Notebooks.FormComponent do
  @moduledoc false
  use ControlServerWeb, :live_component

  alias CommonCore.Notebooks
  alias CommonCore.Notebooks.JupyterLabNotebook
  alias CommonCore.Util.Memory
  alias ControlServer.Notebooks
  alias ControlServer.Projects

  def mount(socket) do
    {:ok, assign_projects(socket)}
  end

  def update(assigns, socket) do
    project_id = Map.get(assigns.notebook, :project_id) || assigns[:project_id]
    changeset = Notebooks.change_jupyter_lab_notebook(assigns.notebook, %{project_id: project_id})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, to_form(changeset))}
  end

  defp assign_projects(socket) do
    assign(socket, projects: Projects.list_projects())
  end

  def handle_event("validate", %{"jupyter_lab_notebook" => params}, socket) do
    changeset =
      socket.assigns.notebook
      |> Notebooks.change_jupyter_lab_notebook(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"jupyter_lab_notebook" => params}, socket) do
    save_notebook(socket, socket.assigns.action, params)
  end

  defp save_notebook(socket, :new, params) do
    case Notebooks.create_jupyter_lab_notebook(params) do
      {:ok, notebook} ->
        {:noreply,
         socket
         |> put_flash(:global_success, "Notebook successfully created")
         |> push_navigate(to: ~p"/notebooks/#{notebook.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_notebook(socket, :edit, params) do
    case Notebooks.update_jupyter_lab_notebook(socket.assigns.notebook, params) do
      {:ok, notebook} ->
        {:noreply,
         socket
         |> put_flash(:global_success, "Notebook successfully updated")
         |> push_navigate(to: ~p"/notebooks/#{notebook.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
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
              do: ~p"/notebooks",
              else: ~p"/notebooks/#{@notebook}"
          }
        >
          <.button variant="dark" type="submit" phx-disable-with="Saving…">
            Save Notebook
          </.button>
        </.page_header>

        <.grid columns={[sm: 1, lg: 2]}>
          <.panel class="col-span-2">
            <.grid columns={[sm: 1, lg: 2]} class="items-center">
              <.input field={@form[:name]} label="Name" />

              <.input
                field={@form[:virtual_size]}
                type="select"
                label="Size"
                placeholder="Choose a size"
                options={JupyterLabNotebook.preset_options_for_select()}
              />

              <.data_list
                variant="horizontal-bolded"
                class="col-span-2"
                data={[
                  {"Storage size:", Memory.humanize(@form[:storage_size].value)},
                  {"Memory limits:", Memory.humanize(@form[:memory_limits].value)},
                  {"CPU limits:", @form[:cpu_limits].value}
                ]}
              />
            </.grid>
          </.panel>

          <.panel title="Advanced Settings" variant="gray">
            <.flex column>
              <.input field={@form[:image]} label="Image" disabled={@action == :edit} />

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
end
