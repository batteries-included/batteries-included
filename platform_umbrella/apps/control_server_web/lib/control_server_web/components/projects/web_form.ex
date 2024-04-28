defmodule ControlServerWeb.Projects.WebForm do
  @moduledoc false
  use ControlServerWeb, :live_component
  use ControlServerWeb.PostgresFormSubcomponents, form_key: "postgres"

  alias CommonCore.Postgres.Cluster, as: PGCluster
  alias CommonCore.Redis.FailoverCluster, as: RedisCluster
  alias ControlServer.Postgres
  alias ControlServerWeb.Projects.ProjectForm
  alias ControlServerWeb.RedisFormSubcomponents

  def update(assigns, socket) do
    {class, assigns} = Map.pop(assigns, :class)

    project_name = get_in(assigns, [:data, ProjectForm, "name"])

    postgres_changeset =
      PGCluster.changeset(
        KubeServices.SmartBuilder.new_postgres(),
        %{name: "#{project_name}-web"}
      )

    redis_changeset =
      RedisCluster.changeset(
        KubeServices.SmartBuilder.new_redis(),
        %{name: "#{project_name}-web"}
      )

    form =
      to_form(%{
        "project_type" => "external",
        "postgres" => postgres_changeset,
        "redis" => redis_changeset
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
    postgres_changeset =
      %PGCluster{}
      |> PGCluster.changeset(params["postgres"])
      |> Map.put(:action, :validate)

    redis_changeset =
      %RedisCluster{}
      |> RedisCluster.changeset(params["redis"])
      |> Map.put(:action, :validate)

    form =
      params
      |> Map.put("postgres", postgres_changeset)
      |> Map.put("redis", redis_changeset)
      |> to_form()

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("save", params, socket) do
    params =
      Map.take(params, [
        "project_type",
        if(params["db_type"] == "new", do: "postgres"),
        if(params["db_type"] == "existing", do: "postgres_ids"),
        if(params["need_redis"] == "on", do: "redis")
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
        <.input field={@form[:project_type]} type="radio">
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
        />

        <.input field={@form[:need_redis]} type="switch" label="I need a redis instance" />

        <RedisFormSubcomponents.size_form
          class={@form[:need_redis].value != "on" && "hidden"}
          form={to_form(@form[:redis].value, as: :redis)}
        />

        <:actions>
          <%= render_slot(@inner_block) %>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
