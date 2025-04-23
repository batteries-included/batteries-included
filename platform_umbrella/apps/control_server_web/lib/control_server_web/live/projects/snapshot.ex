defmodule ControlServerWeb.Live.ProjectsSnapshot do
  @moduledoc false

  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.PgUserTable

  alias CommonCore.Util.Memory
  alias ControlServer.Projects
  alias ControlServer.Projects.Snapshoter

  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign_project(id)
     |> assign_snapshot()
     |> assign_page_title()
     |> assign_removals([])}
  end

  defp assign_project(socket, id) do
    project = Projects.get_project!(id)

    assign(socket, :project, project)
  end

  defp assign_snapshot(%{assigns: %{project: project}} = socket) do
    {:ok, snapshot} = Snapshoter.take_snapshot(project)
    assign(socket, :snapshot, snapshot)
  end

  defp assign_page_title(socket) do
    assign(socket, :page_title, "Project Snapshot")
  end

  defp assign_removals(socket, removals) do
    assign(socket, :removals, removals)
  end

  defp toggle_removal(socket, removal) do
    new =
      if has_removal?(socket.assigns.removals, removal) do
        Enum.reject(socket.assigns.removals, fn loc ->
          loc == removal
        end)
      else
        [removal | socket.assigns.removals]
      end

    assign_removals(socket, new)
  end

  @impl Phoenix.LiveView
  def handle_event("toggle_remove", params, socket) do
    location = location_from_params(params)
    {:noreply, toggle_removal(socket, location)}
  end

  defp location_from_params(params) do
    params
    |> Enum.filter(fn {key, _value} ->
      String.starts_with?(key, "loc-")
    end)
    |> Enum.map(fn {key, value} ->
      new_key = key |> String.replace("loc-", "") |> String.to_integer()
      {new_key, value}
    end)
    |> Enum.sort_by(fn {key, _value} -> key end)
    |> Enum.map(fn {_key, value} ->
      case Integer.parse(value) do
        {int, _} -> int
        _ -> String.to_existing_atom(value)
      end
    end)
  end

  defp has_removal?(removals, loc) do
    Enum.any?(removals, fn removal ->
      removal == loc
    end)
  end

  defp postgres_list(assigns) do
    ~H"""
    <%= for {pg_cluster, cluster_index} <- Enum.with_index(@snapshot.postgres_clusters) do %>
      <.panel title={"Postgres: #{pg_cluster.name}"}>
        <.flex column>
          <.data_list>
            <:item title="Memory Limits">
              {Memory.humanize(pg_cluster.memory_limits)}
            </:item>
            <:item title="Virtual Size">
              {CommonCore.Util.VirtualSize.get_virtual_size(pg_cluster)}
            </:item>
            <:item title="Num Instances">
              {pg_cluster.num_instances}
            </:item>
          </.data_list>

          <.pg_users_table
            id={"pg-users-table-#{cluster_index}"}
            users={pg_cluster.users}
            cluster={pg_cluster}
            opts={[
              tbody_tr_attrs: fn {_, user_index} ->
                if has_removal?(@removals, [:postgres_clusters, cluster_index, :users, user_index]),
                  do: %{class: "line-through"},
                  else: %{}
              end
            ]}
          >
            <:action :let={{_user, user_index}}>
              <.button
                phx-click="toggle_remove"
                phx-value-loc-0="postgres_clusters"
                phx-value-loc-1={cluster_index}
                phx-value-loc-2="users"
                phx-value-loc-3={user_index}
                icon={:trash}
              >
                Toggle Export
              </.button>
            </:action>
          </.pg_users_table>
        </.flex>
      </.panel>
    <% end %>
    """
  end

  defp redis_list(assigns) do
    ~H"""
    <%= for {redis_instance, instance_index} <- Enum.with_index(@snapshot.redis_instances) do %>
      <.panel title={"Redis: #{redis_instance.name}"}>
        <.flex column></.flex>
        <.data_list>
          <:item title="Memory Limits">
            {Memory.humanize(redis_instance.memory_limits)}
          </:item>
          <:item title="Virtual Size">
            {CommonCore.Util.VirtualSize.get_virtual_size(redis_instance)}
          </:item>
          <:item title="Num Instances">
            {redis_instance.num_instances}
          </:item>
        </.data_list>
      </.panel>
    <% end %>
    """
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header back_link={~p"/projects"} title={@page_title}>
      <.button variant="dark" phx-click="export_snapshot" icon={:arrow_up_on_square_stack}>
        Export
      </.button>
    </.page_header>
    <.grid columns={%{sm: 1, lg: 2}} class="w-full">
      <.postgres_list snapshot={@snapshot} removals={@removals} />
      <.redis_list snapshot={@snapshot} removals={@removals} />
    </.grid>
    """
  end
end
