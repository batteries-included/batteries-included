defmodule ControlServerWeb.Projects.WebForm do
  @moduledoc false
  use ControlServerWeb, :live_component

  alias CommonCore.Ecto.Validations
  alias CommonCore.Knative.Service, as: KnativeService
  alias CommonCore.Postgres.Cluster, as: PGCluster
  alias CommonCore.Redis.RedisInstance, as: RedisCluster
  alias CommonCore.TraditionalServices.Service, as: TraditionalService
  alias ControlServer.Postgres
  alias ControlServerWeb.KnativeFormSubcomponents
  alias ControlServerWeb.PostgresFormSubcomponents
  alias ControlServerWeb.Projects.ProjectForm
  alias ControlServerWeb.RedisFormSubcomponents
  alias ControlServerWeb.TraditionalFormSubcomponents

  def update(assigns, socket) do
    {class, assigns} = Map.pop(assigns, :class)

    form_data = get_in(assigns, [:data, __MODULE__]) || %{}
    resource_name = ProjectForm.get_name_for_resource(assigns)

    knative_changeset =
      KnativeService.changeset(
        %KnativeService{},
        Map.get(form_data, "knative", %{name: resource_name})
      )

    traditional_changeset =
      TraditionalService.changeset(
        KubeServices.SmartBuilder.new_traditional_service(),
        Map.get(form_data, "traditional", %{name: resource_name})
      )

    postgres_changeset =
      PGCluster.changeset(
        KubeServices.SmartBuilder.new_postgres(),
        Map.get(form_data, "postgres", %{name: resource_name}),
        range_ticks: PGCluster.compact_storage_range_ticks()
      )

    redis_changeset =
      RedisCluster.changeset(
        KubeServices.SmartBuilder.new_redis(),
        Map.get(form_data, "redis", %{name: resource_name})
      )

    form =
      to_form(%{
        "need_postgres" => Map.get(form_data, "need_postgres", false),
        "need_redis" => Map.get(form_data, "need_redis", false),
        "knative" => knative_changeset,
        "traditional" => traditional_changeset,
        "postgres" => postgres_changeset,
        "redis" => redis_changeset
      })

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, form)
     |> assign(:class, class)
     |> assign(:db_type, Map.get(form_data, "db_type", :new))
     |> assign(:service_type, Map.get(form_data, "service_type", :knative))}
  end

  def handle_event("db_type", %{"type" => type}, socket) do
    {:noreply, assign(socket, :db_type, String.to_existing_atom(type))}
  end

  def handle_event("service_type", %{"type" => type}, socket) do
    {:noreply, assign(socket, :service_type, String.to_existing_atom(type))}
  end

  def handle_event("validate", params, socket) do
    knative_changeset =
      %KnativeService{}
      |> KnativeService.changeset(params["knative"])
      |> Map.put(:action, :validate)

    traditional_changeset =
      %TraditionalService{}
      |> TraditionalService.changeset(params["traditional"])
      |> Map.put(:action, :validate)

    postgres_changeset =
      %PGCluster{}
      |> PGCluster.changeset(params["postgres"], range_ticks: PGCluster.compact_storage_range_ticks())
      |> Map.put(:action, :validate)

    redis_changeset =
      %RedisCluster{}
      |> RedisCluster.changeset(params["redis"])
      |> Map.put(:action, :validate)

    form =
      params
      |> Map.put("knative", knative_changeset)
      |> Map.put("traditional", traditional_changeset)
      |> Map.put("postgres", postgres_changeset)
      |> Map.put("redis", redis_changeset)
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
      params
      |> Map.take([
        "need_postgres",
        "need_redis",
        if(params["service_type"] == "knative", do: "knative"),
        if(params["service_type"] == "traditional", do: "traditional"),
        if(normalize_value("checkbox", params["need_postgres"]) && params["db_type"] == "new", do: "postgres"),
        if(normalize_value("checkbox", params["need_postgres"]) && params["db_type"] == "existing", do: "postgres_ids"),
        if(normalize_value("checkbox", params["need_redis"]), do: "redis")
      ])
      |> Map.put("db_type", socket.assigns.db_type)
      |> Map.put("service_type", socket.assigns.service_type)

    if Validations.subforms_valid?(params, %{
         "knative" => &KnativeService.changeset(%KnativeService{}, &1),
         "traditional" => &TraditionalService.changeset(%TraditionalService{}, &1),
         "postgres" => &PGCluster.changeset(%PGCluster{}, &1, range_ticks: PGCluster.compact_storage_range_ticks()),
         "redis" => &RedisCluster.changeset(%RedisCluster{}, &1)
       }) do
      # Don't create the resources yet, send data to parent liveview
      send(self(), {:next, {__MODULE__, params}})
    end

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
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        description={~s"
        Choose between a Knative (serverless) or Traditional Service web project, and attach an optional database and cache.

        The database URL will automatically be added to the instance's environment variables.
        "}
      >
        <.input type="hidden" name="service_type" value={@service_type} />

        <.tab_bar variant="secondary">
          <:tab
            phx-click="service_type"
            phx-value-type={:knative}
            phx-target={@myself}
            selected={@service_type == :knative}
          >
            Knative
          </:tab>

          <:tab
            phx-click="service_type"
            phx-value-type={:traditional}
            phx-target={@myself}
            selected={@service_type == :traditional}
          >
            Traditional Service
          </:tab>
        </.tab_bar>

        <.grid columns={2}>
          <.light_text>
            Knative services are serverless, and allow you to scale to zero as a request-driven approach to HTTP services.
          </.light_text>
          <.light_text>
            Traditional services are useful for long-running processes that don't conform to serverless. Choose this if you need OAuth support.
          </.light_text>
        </.grid>

        <KnativeFormSubcomponents.main_panel
          form={to_form(@form[:knative].value, as: :knative)}
          class={@service_type != :knative && "hidden"}
        />

        <TraditionalFormSubcomponents.main_panel
          form={to_form(@form[:traditional].value, as: :traditional)}
          class={@service_type != :traditional && "hidden"}
          with_divider={false}
        />

        <.flex class="justify-between w-full pt-3 border-t border-gray-lighter dark:border-gray-darker" />

        <.input field={@form[:need_postgres]} type="switch" label="I need a database" />

        <.flex column class={!normalize_value("checkbox", @form[:need_postgres].value) && "hidden"}>
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
            action={:new}
          />
        </.flex>

        <.input field={@form[:need_redis]} type="switch" label="I need a redis instance" />

        <RedisFormSubcomponents.size_form
          class={!normalize_value("checkbox", @form[:need_redis].value) && "hidden"}
          form={to_form(@form[:redis].value, as: :redis)}
          action={:new}
        />

        <:actions>
          <%= render_slot(@inner_block) %>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
