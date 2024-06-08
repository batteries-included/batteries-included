defmodule ControlServerWeb.Projects.AIForm do
  @moduledoc false
  use ControlServerWeb, :live_component

  alias CommonCore.Notebooks.JupyterLabNotebook
  alias CommonCore.Postgres.Cluster
  alias CommonCore.Util.Memory
  alias ControlServer.Postgres
  alias ControlServerWeb.PostgresFormSubcomponents
  alias ControlServerWeb.Projects.ProjectForm

  def update(assigns, socket) do
    {class, assigns} = Map.pop(assigns, :class)

    project_name = get_in(assigns, [:data, ProjectForm, "name"])

    jupyter_changeset =
      JupyterLabNotebook.changeset(
        KubeServices.SmartBuilder.new_jupyter(),
        %{name: "#{project_name}-notebook"}
      )

    postgres_changeset =
      Cluster.changeset(
        KubeServices.SmartBuilder.new_postgres(),
        %{name: "#{project_name}-notebook"},
        Cluster.compact_storage_range_ticks()
      )

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
      |> Cluster.changeset(params["postgres"], Cluster.compact_storage_range_ticks())
      |> Map.put(:action, :validate)

    form =
      params
      |> Map.put("jupyter", to_form(jupyter_changeset, as: :jupyter))
      |> Map.put("postgres", postgres_changeset)
      |> to_form()

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("change_storage_size_range", %{"value" => value}, socket) do
    handle_event(
      "change_storage_size_range",
      %{"postgres" => %{"virtual_storage_size_range_value" => value}},
      socket
    )
  end

  def handle_event(
        "change_storage_size_range",
        %{"postgres" => %{"virtual_storage_size_range_value" => range_value}},
        socket
      ) do
    postgres_changeset =
      socket.assigns.form.params["postgres"]
      |> Cluster.put_storage_size(range_value, Cluster.compact_storage_range_ticks())
      |> Map.put(:action, :validate)

    form =
      socket.assigns.form.params
      |> Map.put("postgres", postgres_changeset)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", params, socket) do
    params =
      Map.take(params, [
        "jupyter",
        if(params["need_postgres"] == "on" && params["db_type"] == "new", do: "postgres"),
        if(params["need_postgres"] == "on" && params["db_type"] == "existing", do: "postgres_ids")
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
        title="Artificial Intelligence"
        description="A place for information about the AI stage of project creation"
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

        <.data_list
          variant="horizontal-bolded"
          class="mt-3 mb-5"
          data={[
            {"Storage size:", Memory.humanize(@form[:jupyter].value[:storage_size].value)},
            {"Memory limits:", Memory.humanize(@form[:jupyter].value[:memory_limits].value)},
            {"CPU limits:", @form[:jupyter].value[:cpu_limits].value}
          ]}
        />

        <.flex class="justify-between w-full py-3 border-t border-gray-lighter dark:border-gray-darker" />

        <.input field={@form[:need_postgres]} type="switch" label="I need a database" />

        <div class={@form[:need_postgres].value != "on" && "hidden"}>
          <.tab_bar variant="secondary" class="mb-6">
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
            ticks={Cluster.compact_storage_range_ticks()}
          />
        </div>

        <:actions>
          <%= render_slot(@inner_block) %>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end