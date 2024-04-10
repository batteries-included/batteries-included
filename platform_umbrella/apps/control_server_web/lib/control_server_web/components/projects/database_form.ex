defmodule ControlServerWeb.Projects.DatabaseForm do
  @moduledoc false
  use ControlServerWeb, :live_component

  alias CommonCore.Postgres.Cluster, as: PGCluster
  alias CommonCore.Redis.FailoverCluster, as: RedisCluster
  alias ControlServerWeb.PostgresFormSubcomponents
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

  def handle_event("set_storage_size_shortcut", %{"bytes" => bytes}, socket) do
    handle_event("change_storage_size", %{"postgres" => %{"storage_size" => bytes}}, socket)
  end

  # This only happens when the user is manually editing the storage size.
  # In this case, we need to update the range slider and helper text "x GB"
  def handle_event("change_storage_size", %{"postgres" => %{"storage_size" => storage_size}}, socket) do
    changeset = PGCluster.put_storage_size_bytes(socket.assigns.form.params["postgres"], storage_size)

    form =
      socket.assigns.form.params
      |> Map.put("postgres", changeset)
      |> to_form()

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event(
        "on_change_storage_size_range",
        %{"postgres" => %{"virtual_storage_size_range_value" => virtual_storage_size_range_value}},
        socket
      ) do
    changeset = PGCluster.put_storage_size_value(socket.assigns.form.params["postgres"], virtual_storage_size_range_value)

    form =
      socket.assigns.form.params
      |> Map.put("postgres", changeset)
      |> to_form()

    {:noreply, assign(socket, form: form)}
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

        <.flex
          :if={@form[:need_postgres].value}
          class="justify-between w-full py-3 border-t border-gray-lighter dark:border-gray-darker"
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
