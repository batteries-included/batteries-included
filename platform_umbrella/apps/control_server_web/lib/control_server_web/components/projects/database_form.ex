defmodule ControlServerWeb.Projects.DatabaseForm do
  @moduledoc false
  use ControlServerWeb, :live_component

  alias CommonCore.Ecto.Validations
  alias CommonCore.FerretDB.FerretService
  alias CommonCore.Postgres.Cluster, as: PGCluster
  alias CommonCore.Redis.RedisInstance, as: RedisCluster
  alias ControlServerWeb.FerretDBFormSubcomponents
  alias ControlServerWeb.PostgresFormSubcomponents
  alias ControlServerWeb.Projects.ProjectForm
  alias ControlServerWeb.RedisFormSubcomponents

  @description """
  Database-only projects are just what they sound like—they don't require any other resources outside of a database and caching layer.

  If a FerretDB instance is created, it will automatically be attached to the Postgres cluster.
  """

  def update(assigns, socket) do
    {class, assigns} = Map.pop(assigns, :class)

    form_data = get_in(assigns, [:data, __MODULE__]) || %{}
    resource_name = ProjectForm.get_name_for_resource(assigns)

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

    ferret_changeset =
      FerretService.changeset(
        KubeServices.SmartBuilder.new_ferretdb(),
        Map.get(form_data, "ferret", %{name: resource_name})
      )

    form =
      to_form(%{
        "need_postgres" => Map.get(form_data, "need_postgres", true),
        "need_redis" => Map.get(form_data, "need_redis", false),
        "need_ferret" => Map.get(form_data, "need_ferret", false),
        "postgres" => postgres_changeset,
        "redis" => redis_changeset,
        "ferret" => ferret_changeset
      })

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, form)
     |> assign(:class, class)}
  end

  def handle_event("validate", params, socket) do
    postgres_changeset =
      %PGCluster{}
      |> PGCluster.changeset(params["postgres"], range_ticks: PGCluster.compact_storage_range_ticks())
      |> Map.put(:action, :validate)

    redis_changeset =
      %RedisCluster{}
      |> RedisCluster.changeset(params["redis"])
      |> Map.put(:action, :validate)

    ferret_changeset =
      %FerretService{}
      |> FerretService.changeset(params["ferret"])
      |> Map.put(:action, :validate)

    params =
      if params["need_postgres"] == "false" do
        Map.put(params, "need_ferret", "false")
      else
        params
      end

    form =
      params
      |> Map.put("postgres", postgres_changeset)
      |> Map.put("redis", redis_changeset)
      |> Map.put("ferret", ferret_changeset)
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
        "need_postgres",
        "need_redis",
        "need_ferret",
        if(normalize_value("checkbox", params["need_postgres"]), do: "postgres"),
        if(normalize_value("checkbox", params["need_redis"]), do: "redis"),
        if(normalize_value("checkbox", params["need_postgres"]) && normalize_value("checkbox", params["need_ferret"]),
          do: "ferret"
        )
      ])

    if Validations.subforms_valid?(params, %{
         "postgres" => &PGCluster.changeset(%PGCluster{}, &1, range_ticks: PGCluster.compact_storage_range_ticks()),
         "redis" => &RedisCluster.changeset(%RedisCluster{}, &1),
         "ferret" => &FerretService.changeset(%FerretService{}, &1)
       }) do
      # Don't create the resources yet, send data to parent liveview
      send(self(), {:next, {__MODULE__, params}})
    end

    {:noreply, socket}
  end

  def render(assigns) do
    assigns = assign(assigns, :description, @description)

    ~H"""
    <div class="contents">
      <.simple_form
        id={@id}
        for={@form}
        class={@class}
        variant="stepped"
        title="Database Only"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        description={@description}
      >
        <.input field={@form[:need_postgres]} type="switch" label="I need a Postgres instance" />

        <PostgresFormSubcomponents.size_form
          class={!normalize_value("checkbox", @form[:need_postgres].value) && "hidden"}
          form={to_form(@form[:postgres].value, as: :postgres)}
          phx_target={@myself}
          ticks={PGCluster.compact_storage_range_ticks()}
          action={:new}
        />

        <.input field={@form[:need_redis]} type="switch" label="I need a Redis instance" />

        <RedisFormSubcomponents.size_form
          class={!normalize_value("checkbox", @form[:need_redis].value) && "hidden"}
          form={to_form(@form[:redis].value, as: :redis)}
          action={:new}
        />

        <.input
          field={@form[:need_ferret]}
          type="switch"
          label="I need a FerretDB/MongoDB instance"
          disabled={@form[:need_postgres].value == "false"}
        />

        <FerretDBFormSubcomponents.size_form
          class={
            (!normalize_value("checkbox", @form[:need_postgres].value) ||
               !normalize_value("checkbox", @form[:need_ferret].value)) && "hidden"
          }
          form={to_form(@form[:ferret].value, as: :ferret)}
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
