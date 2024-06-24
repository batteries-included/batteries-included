defmodule ControlServerWeb.Live.Redis.FormComponent do
  @moduledoc false
  use ControlServerWeb, :live_component

  import ControlServerWeb.RedisFormSubcomponents

  alias CommonCore.Util.Integer
  alias ControlServer.Redis

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.form
        for={@form}
        id="failover_cluster-form"
        phx-change="validate"
        phx-submit="save"
        phx-target={@myself}
      >
        <.page_header
          title={@title}
          back_link={if @action == :new, do: ~p"/redis", else: ~p"/redis/#{@failover_cluster}/show"}
        >
          <.button variant="dark" type="submit" phx-disable-with="Saving…">
            Save Cluster
          </.button>
        </.page_header>

        <.grid columns={%{sm: 1, lg: 2}}>
          <.panel>
            <.size_form form={@form} action={@action} />

            <.flex class="justify-between w-full py-5 border-t border-gray-lighter dark:border-gray-darker" />

            <.grid columns={[sm: 1, lg: 2]} class="items-center">
              <.h5>Number of instances</.h5>
              <.input field={@form[:num_redis_instances]} type="range" min="1" max="3" step="1" />
            </.grid>
            <.grid
              :if={@form[:num_redis_instances].value |> Integer.to_integer() > 1}
              columns={[sm: 1, lg: 2]}
              class="items-center"
            >
              <.h5>Number of sentinel instances</.h5>
              <.input field={@form[:num_sentinel_instances]} type="range" min="1" max="3" step="1" />
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
  def update(%{failover_cluster: failover_cluster} = assigns, socket) do
    project_id = Map.get(failover_cluster, :project_id) || assigns[:project_id]
    changeset = Redis.change_failover_cluster(failover_cluster, %{project_id: project_id})

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)
     |> assign_projects()}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"failover_cluster" => failover_cluster_params}, socket) do
    changeset =
      socket.assigns.failover_cluster
      |> Redis.change_failover_cluster(failover_cluster_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"failover_cluster" => failover_cluster_params}, socket) do
    save_failover_cluster(socket, socket.assigns.action, failover_cluster_params)
  end

  defp save_failover_cluster(socket, :edit, failover_cluster_params) do
    case Redis.update_failover_cluster(socket.assigns.failover_cluster, failover_cluster_params) do
      {:ok, failover_cluster} ->
        notify_parent({:saved, failover_cluster})

        {:noreply,
         socket
         |> put_flash(:global_success, "Failover cluster updated successfully")
         |> push_navigate(to: ~p"/redis/#{failover_cluster.id}/show")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_failover_cluster(socket, :new, failover_cluster_params) do
    case Redis.create_failover_cluster(failover_cluster_params) do
      {:ok, failover_cluster} ->
        notify_parent({:saved, failover_cluster})

        {:noreply,
         socket
         |> put_flash(:global_success, "Failover cluster created successfully")
         |> push_navigate(to: ~p"/redis/#{failover_cluster.id}/show")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp assign_projects(socket) do
    projects = ControlServer.Projects.list_projects()
    assign(socket, projects: projects)
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
