defmodule ControlServerWeb.Live.Redis.FormComponent do
  @moduledoc false
  use ControlServerWeb, :live_component

  import ControlServerWeb.RedisFormSubcomponents

  alias ControlServer.Redis
  alias Ecto.Changeset

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.form
        for={@form}
        id="redis_instance-form"
        phx-change="validate"
        phx-submit="save"
        phx-target={@myself}
      >
        <.page_header
          title={@title}
          back_link={if @action == :new, do: ~p"/redis", else: ~p"/redis/#{@redis_instance}/show"}
        >
          <.button variant="dark" type="submit" phx-disable-with="Saving…">
            Save Redis
          </.button>
        </.page_header>

        <.grid columns={%{sm: 1, lg: 2}}>
          <.panel>
            <.size_form form={@form} action={@action} />

            <.flex
              :if={@instance_type != :standalone}
              class="justify-between w-full py-5 border-t border-gray-lighter dark:border-gray-darker"
            />

            <.grid :if={@instance_type != :standalone} columns={[sm: 1, lg: 2]} class="items-center">
              <.h5>Number of instances {@instance_type}</.h5>
              <.input
                field={@form[:num_instances]}
                type="range"
                min="1"
                max={max(min(@num_nodes, 20), 3)}
                step="1"
              />
            </.grid>
          </.panel>

          <.panel title="Advanced Settings" variant="gray">
            <.flex column>
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

  @impl Phoenix.LiveComponent
  def update(%{redis_instance: redis_instance} = assigns, socket) do
    project_id = Map.get(redis_instance, :project_id) || assigns[:project_id]
    changeset = Redis.change_redis_instance(redis_instance, %{project_id: project_id})

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)
     |> assign_num_nodes()
     |> assign_projects()}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"redis_instance" => redis_instance_params}, socket) do
    changeset =
      socket.assigns.redis_instance
      |> Redis.change_redis_instance(redis_instance_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"redis_instance" => redis_instance_params}, socket) do
    save_redis_instance(socket, socket.assigns.action, redis_instance_params)
  end

  defp save_redis_instance(socket, :edit, redis_instance_params) do
    case Redis.update_redis_instance(socket.assigns.redis_instance, redis_instance_params) do
      {:ok, redis_instance} ->
        notify_parent({:saved, redis_instance})

        {:noreply,
         socket
         |> put_flash(:global_success, "Redis instance updated successfully")
         |> push_navigate(to: ~p"/redis/#{redis_instance.id}/show")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_redis_instance(socket, :new, redis_instance_params) do
    case Redis.create_redis_instance(redis_instance_params) do
      {:ok, redis_instance} ->
        notify_parent({:saved, redis_instance})

        {:noreply,
         socket
         |> put_flash(:global_success, "Redis instance created successfully")
         |> push_navigate(to: ~p"/redis/#{redis_instance.id}/show")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    socket
    |> assign(:form, to_form(changeset))
    |> assign(:instance_type, Changeset.get_field(changeset, :instance_type))
  end

  defp assign_projects(socket) do
    projects = ControlServer.Projects.list_projects()
    assign(socket, projects: projects)
  end

  defp assign_num_nodes(socket) do
    num_nodes = :node |> KubeServices.KubeState.get_all() |> Enum.count()
    assign(socket, num_nodes: num_nodes)
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
