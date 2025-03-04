defmodule ControlServerWeb.Live.Notebooks.FormComponent do
  @moduledoc false
  use ControlServerWeb, :live_component

  import ControlServerWeb.Containers.EnvValuePanel
  import ControlServerWeb.Containers.HiddenForms

  alias CommonCore.Containers.EnvValue
  alias CommonCore.Defaults.GPU
  alias CommonCore.Notebooks
  alias CommonCore.Notebooks.JupyterLabNotebook
  alias CommonCore.Util.Memory
  alias ControlServer.Notebooks
  alias ControlServer.Projects
  alias Ecto.Changeset
  alias KubeServices.SystemState.SummaryBatteries

  def mount(socket) do
    {:ok,
     socket
     |> assign_new(:namespace, fn -> SummaryBatteries.ai_namespace() end)
     |> assign_projects()
     |> assign_env_value(nil)
     |> assign_env_value_idx(nil)}
  end

  defp assign_projects(socket) do
    assign(socket, projects: Projects.list_projects())
  end

  defp assign_env_value(socket, env_value) do
    assign(socket, env_value: env_value)
  end

  defp assign_env_value_idx(socket, idx) do
    assign(socket, env_value_idx: idx)
  end

  defp assign_changeset(socket, changeset) do
    env_values = Changeset.get_field(changeset, :env_values, [])

    assign(socket,
      changeset: changeset,
      form: to_form(changeset),
      env_values: env_values
    )
  end

  def update(%{env_value: nil}, socket) do
    {:ok, socket |> assign_env_value(nil) |> assign_env_value_idx(nil)}
  end

  def update(%{env_value: env_value, idx: nil}, %{assigns: %{changeset: changeset}} = socket) do
    env_values = Changeset.get_field(changeset, :env_values, [])
    changeset = Changeset.put_embed(changeset, :env_values, [env_value | env_values])

    {:ok, socket |> assign_env_value(nil) |> assign_env_value_idx(nil) |> assign_changeset(changeset)}
  end

  def update(%{env_value: env_value, idx: idx}, %{assigns: %{changeset: changeset}} = socket) do
    env_values =
      changeset
      |> Changeset.get_field(:env_values, [])
      |> List.replace_at(idx, env_value)

    changeset = Changeset.put_embed(changeset, :env_values, env_values)

    {:ok, socket |> assign_env_value(nil) |> assign_env_value_idx(nil) |> assign_changeset(changeset)}
  end

  def update(assigns, socket) do
    project_id = Map.get(assigns.notebook, :project_id) || assigns[:project_id]
    changeset = Notebooks.change_jupyter_lab_notebook(assigns.notebook, %{project_id: project_id})

    {:ok,
     socket
     |> assign(assigns)
     |> assign_changeset(changeset)}
  end

  def handle_event("new_env_value", _, socket) do
    new_env_var = %EnvValue{source_type: :value}
    {:noreply, socket |> assign_env_value(new_env_var) |> assign_env_value_idx(nil)}
  end

  def handle_event("edit:env_value", %{"idx" => idx_string}, %{assigns: %{changeset: changeset}} = socket) do
    {idx, _} = Integer.parse(idx_string)

    env_values = Changeset.get_field(changeset, :env_values, [])
    env_value = Enum.fetch!(env_values, idx)

    {:noreply, socket |> assign_env_value(env_value) |> assign_env_value_idx(idx)}
  end

  def handle_event("del:env_value", %{"idx" => env_value_idx}, %{assigns: %{changeset: changeset}} = socket) do
    {idx, ""} = Integer.parse(env_value_idx)

    env_values = changeset |> Changeset.get_field(:env_values, []) |> List.delete_at(idx)
    new_changeset = Changeset.put_embed(changeset, :env_values, env_values)

    {:noreply, assign_changeset(socket, new_changeset)}
  end

  def handle_event("validate", %{"jupyter_lab_notebook" => params}, socket) do
    changeset =
      socket.assigns.notebook
      |> Notebooks.change_jupyter_lab_notebook(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_changeset(socket, changeset)}
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
        {:noreply, assign_changeset(socket, changeset)}
    end
  end

  defp save_notebook(socket, :edit, params) do
    params = Map.put_new(params, "env_values", %{})

    case Notebooks.update_jupyter_lab_notebook(socket.assigns.notebook, params) do
      {:ok, notebook} ->
        {:noreply,
         socket
         |> put_flash(:global_success, "Notebook successfully updated")
         |> push_navigate(to: ~p"/notebooks/#{notebook.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_changeset(socket, changeset)}
    end
  end

  defp update_env_value(env_value, idx) do
    send_update(__MODULE__, id: "notebook-form", env_value: env_value, idx: idx)
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
              <.input field={@form[:name]} label="Name" disabled={@action != :new} />

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

          <.env_var_panel env_values={@env_values} editable target={@myself} />
          <!-- Hidden inputs for embeds -->
          <.env_values_hidden_form field={@form[:env_values]} />

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

              <.input
                field={@form[:node_type]}
                type="select"
                label="GPU"
                placeholder="None"
                options={GPU.node_types_for_select()}
              />
            </.flex>
          </.panel>
        </.grid>
      </.form>

      <.live_component
        :if={@env_value}
        module={ControlServerWeb.Containers.EnvValueModal}
        namespace={@namespace}
        update_func={&update_env_value/2}
        env_value={@env_value}
        idx={@env_value_idx}
        id="env-form-modal"
      />
    </div>
    """
  end
end
