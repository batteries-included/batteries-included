defmodule ControlServerWeb.Projects.WebForm do
  @moduledoc false
  use ControlServerWeb, :live_component

  alias CommonCore.Backend.Service, as: BackendService
  alias CommonCore.Batteries.Catalog
  alias CommonCore.Knative.Service, as: KnativeService
  alias CommonCore.Postgres.Cluster, as: PGCluster
  alias CommonCore.Redis.FailoverCluster, as: RedisCluster
  alias ControlServer.Postgres
  alias ControlServerWeb.BackendFormSubcomponents
  alias ControlServerWeb.KnativeFormSubcomponents
  alias ControlServerWeb.PostgresFormSubcomponents
  alias ControlServerWeb.Projects.ProjectForm
  alias ControlServerWeb.RedisFormSubcomponents

  def update(assigns, socket) do
    {class, assigns} = Map.pop(assigns, :class)

    project_name = get_in(assigns, [:data, ProjectForm, "name"])

    postgres_changeset =
      PGCluster.changeset(
        KubeServices.SmartBuilder.new_postgres(),
        %{name: "#{project_name}-web"},
        PGCluster.compact_storage_range_ticks()
      )

    redis_changeset =
      RedisCluster.changeset(
        KubeServices.SmartBuilder.new_redis(),
        %{name: "#{project_name}-web"}
      )

    knative_changeset =
      KnativeService.changeset(
        %KnativeService{},
        %{name: "#{project_name}-web"}
      )

    backend_changeset =
      BackendService.changeset(
        KubeServices.SmartBuilder.new_backend_service(),
        %{name: "#{project_name}-web"}
      )

    form =
      to_form(%{
        "web_type" => "external",
        "postgres" => postgres_changeset,
        "redis" => redis_changeset,
        "knative" => knative_changeset,
        "backend" => backend_changeset
      })

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:class, class)
     |> assign(:db_type, :new)
     |> assign(:backend_type, :knative)
     |> assign(:form, form)}
  end

  def handle_event("db_type", %{"type" => type}, socket) do
    {:noreply, assign(socket, :db_type, String.to_existing_atom(type))}
  end

  def handle_event("backend_type", %{"type" => type}, socket) do
    {:noreply, assign(socket, :backend_type, String.to_existing_atom(type))}
  end

  def handle_event("validate", params, socket) do
    postgres_changeset =
      %PGCluster{}
      |> PGCluster.changeset(params["postgres"], PGCluster.compact_storage_range_ticks())
      |> Map.put(:action, :validate)

    redis_changeset =
      %RedisCluster{}
      |> RedisCluster.changeset(params["redis"])
      |> Map.put(:action, :validate)

    knative_changeset =
      %KnativeService{}
      |> KnativeService.changeset(params["knative"])
      |> Map.put(:action, :validate)

    backend_changeset =
      %BackendService{}
      |> BackendService.changeset(params["backend"])
      |> Map.put(:action, :validate)

    form =
      params
      |> Map.put("postgres", postgres_changeset)
      |> Map.put("redis", redis_changeset)
      |> Map.put("knative", knative_changeset)
      |> Map.put("backend", backend_changeset)
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
      |> PGCluster.put_storage_size(range_value, PGCluster.compact_storage_range_ticks())
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
        "web_type",
        if(params["db_type"] == "new", do: "postgres"),
        if(params["db_type"] == "existing", do: "postgres_ids"),
        if(normalize_value("checkbox", params["need_redis"]), do: "redis"),
        if(normalize_value("checkbox", params["need_backend"]) && params["backend_type"] == "knative", do: "knative"),
        if(normalize_value("checkbox", params["need_backend"]) && params["backend_type"] == "backend", do: "backend")
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
        title="Web"
        description="A place for information about the web stage of project creation"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:web_type]} type="radio">
          <:option value="internal">Internal web project</:option>
          <:option value="external">External web project</:option>
        </.input>

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
          ticks={PGCluster.compact_storage_range_ticks()}
        />

        <.input field={@form[:need_redis]} type="switch" label="I need a redis instance" />

        <RedisFormSubcomponents.size_form
          class={!normalize_value("checkbox", @form[:need_redis].value) && "hidden"}
          form={to_form(@form[:redis].value, as: :redis)}
        />

        <.flex class="justify-between w-full pt-3 border-t border-gray-lighter dark:border-gray-darker" />

        <.input field={@form[:need_backend]} type="switch" label="I need a backend" />

        <.flex column class={!normalize_value("checkbox", @form[:need_backend].value) && "hidden"}>
          <.input type="hidden" name="backend_type" value={@backend_type} />

          <.tab_bar variant="secondary">
            <:tab
              phx-click="backend_type"
              phx-value-type={:knative}
              phx-target={@myself}
              selected={@backend_type == :knative}
            >
              Knative
            </:tab>

            <:tab
              phx-click="backend_type"
              phx-value-type={:backend}
              phx-target={@myself}
              selected={@backend_type == :backend}
            >
              Backend Service
            </:tab>
          </.tab_bar>

          <.grid columns={2}>
            <.light_text><%= Catalog.get(:knative).description %></.light_text>
            <.light_text><%= Catalog.get(:backend_services).description %></.light_text>
          </.grid>

          <KnativeFormSubcomponents.main_panel
            form={to_form(@form[:knative].value, as: :knative)}
            class={
              (!normalize_value("checkbox", @form[:need_backend].value) || @backend_type != :knative) &&
                "hidden"
            }
          />

          <BackendFormSubcomponents.main_panel
            form={to_form(@form[:backend].value, as: :backend)}
            class={
              (!normalize_value("checkbox", @form[:need_backend].value) || @backend_type != :backend) &&
                "hidden"
            }
          />
        </.flex>

        <:actions>
          <%= render_slot(@inner_block) %>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
