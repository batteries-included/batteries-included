defmodule ControlServerWeb.Projects.DatabaseForm do
  @moduledoc false
  use ControlServerWeb, :live_component
  use ControlServerWeb.PostgresFormSubcomponents, form_key: "postgres"

  alias CommonCore.Postgres.Cluster, as: PGCluster
  alias CommonCore.Redis.FailoverCluster, as: RedisCluster
  alias ControlServerWeb.Projects.ProjectForm
  alias ControlServerWeb.RedisFormSubcomponents

  def update(assigns, socket) do
    {class, assigns} = Map.pop(assigns, :class)

    project_name = get_in(assigns, [:data, ProjectForm, "name"])

    postgres_changeset =
      PGCluster.changeset(%PGCluster{}, %{
        name: project_name,
        virtual_size: "medium"
      })

    redis_changeset =
      RedisCluster.changeset(%RedisCluster{}, %{
        name: project_name,
        virtual_size: "small"
      })

    form =
      to_form(%{
        "need_postgres" => "on",
        "postgres" => postgres_changeset,
        "redis" => redis_changeset
      })

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:class, class)
     |> assign(:form, form)}
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
      |> Map.put("redis", redis_changeset)
      |> Map.put("postgres", postgres_changeset)
      |> to_form()

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("save", params, socket) do
    params =
      Map.take(params, [
        if(params["need_postgres"] == "on", do: "postgres"),
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
        title="Database Only"
        description="A place for information about the database stage of project creation"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:need_postgres]} type="switch" label="I need a postgres instance" />

        <PostgresFormSubcomponents.size_form
          class={@form[:need_postgres].value != "on" && "hidden"}
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
