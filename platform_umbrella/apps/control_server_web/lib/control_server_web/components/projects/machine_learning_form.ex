defmodule ControlServerWeb.Projects.MachineLearningForm do
  @moduledoc false
  use ControlServerWeb, :live_component
  use ControlServerWeb.PostgresFormSubcomponents

  alias CommonCore.Notebooks.JupyterLabNotebook
  alias CommonCore.Postgres.Cluster
  alias CommonCore.Util.Memory
  alias ControlServer.Postgres
  alias ControlServerWeb.Projects.ProjectForm

  def update(assigns, socket) do
    {class, assigns} = Map.pop(assigns, :class)

    project_name = get_in(assigns, [:data, ProjectForm, "name"])

    jupyter_changeset =
      JupyterLabNotebook.changeset(%JupyterLabNotebook{}, %{
        name: "#{project_name}-notebook",
        virtual_size: "small"
      })

    postgres_changeset =
      Cluster.changeset(%Cluster{}, %{
        name: "#{project_name}-notebook",
        virtual_size: "medium"
      })

    form =
      to_form(%{
        "jupyter" => to_form(jupyter_changeset, as: :jupyter),
        "postgres" => postgres_changeset
      })

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:class, class)
     |> assign(:db_type, :new)
     |> assign(:form, form)}
  end

  def handle_event("db_type", %{"type" => type}, socket) do
    {:noreply, assign(socket, :db_type, String.to_existing_atom(type))}
  end

  def handle_event("validate", params, socket) do
    jupyter_changeset =
      %JupyterLabNotebook{}
      |> JupyterLabNotebook.changeset(params["jupyter"])
      |> Map.put(:action, :validate)

    postgres_changeset =
      %Cluster{}
      |> Cluster.changeset(params["postgres"])
      |> Map.put(:action, :validate)

    form =
      params
      |> Map.put("jupyter", to_form(jupyter_changeset, as: :jupyter))
      |> Map.put("postgres", postgres_changeset)
      |> to_form()

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("save", params, socket) do
    params =
      Map.take(params, [
        "jupyter",
        if(params["db_type"] == "new", do: "postgres"),
        if(params["db_type"] == "existing", do: "postgres_ids")
      ])

    # Don't create the resources yet, send data to parent liveview
    send(self(), {:next, {__MODULE__, params}})

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="contents">
      <.simple_form
        id={@id}
        for={@form}
        class={@class}
        variant="stepped"
        title="Machine Learning"
        description="A place for information about the machine learning stage of project creation"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.grid columns={[sm: 1, xl: 2]}>
          <.input field={@form[:jupyter].value[:name]} label="Name of the Jupyter notebook" />

          <.input
            field={@form[:jupyter].value[:virtual_size]}
            type="select"
            label="Size of the Jupyter notebook"
            placeholder="Choose size"
            options={JupyterLabNotebook.preset_options_for_select()}
          />
        </.grid>

        <.data_horizontal_bolded
          class="mt-3 mb-5"
          data={[
            {"Storage size:",
             @form[:jupyter].value[:storage_size].value |> Memory.format_bytes(true) || "0GB"},
            {"Memory limits:",
             @form[:jupyter].value[:memory_limits].value |> Memory.format_bytes(true)},
            {"CPU limits:", @form[:jupyter].value[:cpu_limits].value}
          ]}
        />

        <.flex class="justify-between w-full py-3 border-t border-gray-lighter dark:border-gray-darker" />

        <.tab_bar variant="secondary">
          <:tab
            phx-click="db_type"
            phx-value-type={:new}
            phx-target={@myself}
            selected={@db_type == :new}
          >
            New Database
          </:tab>

          <:tab
            phx-click="db_type"
            phx-value-type={:existing}
            phx-target={@myself}
            selected={@db_type == :existing}
          >
            Existing Database
          </:tab>
        </.tab_bar>

        <.input type="hidden" name="db_type" value={@db_type} />

        <.input
          :if={@db_type == :existing}
          field={@form[:postgres_ids]}
          type="select"
          label="Existing set of databases"
          placeholder="Choose a set of databases"
          options={Postgres.clusters_available_for_project()}
          multiple
        />

        <PostgresFormSubcomponents.size_form
          class={@db_type != :new && "hidden"}
          form={to_form(@form[:postgres].value, as: :postgres)}
          phx_target={@myself}
          with_divider={false}
        />

        <:actions>
          <%= render_slot(@inner_block) %>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
