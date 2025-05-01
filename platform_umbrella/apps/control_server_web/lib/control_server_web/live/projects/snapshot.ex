defmodule ControlServerWeb.Live.ProjectsSnapshot do
  @moduledoc false

  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.Containers.EnvValueTable
  import ControlServerWeb.PgUserTable
  import ControlServerWeb.Projects.ExportToggleButton

  alias CommonCore.Projects.ProjectSnapshot
  alias CommonCore.Util.Memory
  alias ControlServer.Projects
  alias ControlServer.Projects.Snapshoter

  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign_project(id)
     |> assign_snapshot()
     |> assign_form()
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

  defp assign_form(%{assigns: %{snapshot: snapshot}} = socket, params \\ %{}) do
    changeset = ProjectSnapshot.changeset(snapshot, params)
    form = to_form(changeset, as: :snapshot)
    new_snapshot = Ecto.Changeset.apply_changes(changeset)

    socket
    |> assign(:changeset, changeset)
    |> assign(:form, form)
    |> assign(:snapshot, new_snapshot)
  end

  defp assign_page_title(socket) do
    assign(socket, :page_title, "Project Snapshot")
  end

  defp assign_removals(socket, removals) do
    assign(socket, :removals, removals)
  end

  defp has_removal?(removals, loc) do
    Enum.any?(removals, fn removal ->
      removal == loc
    end)
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

  def handle_event("validate", %{"snapshot" => snapshot_params}, socket) do
    {:noreply, assign_form(socket, snapshot_params)}
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
            opts={table_opts(@removals, [:postgres_clusters, cluster_index, :users])}
          >
            <:action :let={{_user, user_index}}>
              <.export_toggle_button
                location={[:postgres_clusters, cluster_index, :users, user_index]}
                removals={@removals}
              />
            </:action>
          </.pg_users_table>
        </.flex>
      </.panel>
    <% end %>
    """
  end

  defp redis_list(assigns) do
    ~H"""
    <%= for redis_instance <- @snapshot.redis_instances do %>
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

  def ferretdb_list(assigns) do
    ~H"""
    <%= for ferret_service <- @snapshot.ferret_services do %>
      <.panel title={"Ferret: #{ferret_service.name}"}>
        <.flex column></.flex>
        <.data_list>
          <:item title="Memory Limits">
            {Memory.humanize(ferret_service.memory_limits)}
          </:item>
          <:item title="Virtual Size">
            {CommonCore.Util.VirtualSize.get_virtual_size(ferret_service)}
          </:item>
        </.data_list>
      </.panel>
    <% end %>
    """
  end

  def jupyter_notebook_list(assigns) do
    ~H"""
    <%= for {jupyter_notebook, jupyter_notebook_idx} <- Enum.with_index(@snapshot.jupyter_notebooks) do %>
      <.panel title={"Jupyter Notebook: #{jupyter_notebook.name}"}>
        <.flex column></.flex>
        <.data_list>
          <:item title="Memory Limits">
            {Memory.humanize(jupyter_notebook.memory_limits)}
          </:item>
          <:item title="Virtual Size">
            {CommonCore.Util.VirtualSize.get_virtual_size(jupyter_notebook)}
          </:item>
        </.data_list>

        <.env_var_table
          :if={jupyter_notebook.env_values != []}
          id={"jupyter-env-var-table-#{jupyter_notebook_idx}"}
          env_values={jupyter_notebook.env_values}
          opts={table_opts(@removals, [:jupyter_notebooks, jupyter_notebook_idx, :env_values])}
        >
          <:action :let={{_env_value, env_value_index}}>
            <.export_toggle_button
              location={[:jupyter_notebooks, jupyter_notebook_idx, :env_values, env_value_index]}
              removals={@removals}
            />
          </:action>
        </.env_var_table>
      </.panel>
    <% end %>
    """
  end

  defp traditional_services_list(assigns) do
    ~H"""
    <%= for {service, service_index} <- Enum.with_index(@snapshot.traditional_services) do %>
      <.panel title={"Traditional Service: #{service.name}"}>
        <.flex column></.flex>
        <.data_list>
          <:item title="Memory Limits">> {Memory.humanize(service.memory_limits)}</:item>
          <:item title="Virtual Size">
            {CommonCore.Util.VirtualSize.get_virtual_size(service)}
          </:item>
        </.data_list>

        <.env_var_table
          :if={service.env_values != []}
          id={"traditional_env-var-table-#{service_index}"}
          env_values={service.env_values}
          opts={table_opts(@removals, [:traditional_services, service_index, :env_values])}
        >
          <:action :let={{_env_value, env_value_index}}>
            <.export_toggle_button
              location={[:traditional_services, service_index, :env_values, env_value_index]}
              removals={@removals}
            />
          </:action>
        </.env_var_table>
      </.panel>
    <% end %>
    """
  end

  defp knative_services_list(assigns) do
    ~H"""
    <%= for {service, service_index} <- Enum.with_index(@snapshot.knative_services) do %>
      <.panel title={"Knative Service: #{service.name}"}>
        <.flex column></.flex>
        <.data_list>
          <:item title="Virtual Size">
            {CommonCore.Util.VirtualSize.get_virtual_size(service)}
          </:item>
        </.data_list>

        <.env_var_table
          :if={service.env_values != []}
          id={"knative_env-var-table-#{service_index}"}
          env_values={service.env_values}
          opts={table_opts(@removals, [:knative_services, service_index, :env_values])}
        >
          <:action :let={{_env_value, env_value_index}}>
            <.export_toggle_button
              location={[:knative_services, service_index, :env_values, env_value_index]}
              removals={@removals}
            />
          </:action>
        </.env_var_table>
      </.panel>
    <% end %>
    """
  end

  defp table_opts(removals, location) do
    [
      tbody_tr_attrs: fn {_, index} ->
        if has_removal?(removals, location ++ [index]),
          do: %{class: "line-through"},
          else: %{}
      end
    ]
  end

  defp snapshot_form_panel(assigns) do
    ~H"""
    <.panel title={"Snapshot: #{@snapshot.name}"}>
      <.flex>
        <.field>
          <:label>Snapshot Name</:label>
          <.input field={@form[:name]} />
        </.field>
        <.field>
          <:label>Description</:label>
          <.input type="textarea" field={@form[:description]} rows="15" />
        </.field>
      </.flex>
    </.panel>
    """
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.form id="snapshot-form" for={@form} novalidate phx-submit="export" phx-change="validate">
      <.page_header back_link={~p"/projects"} title={@page_title}>
        <.button variant="dark" type="submit" icon={:arrow_up_on_square_stack}>
          Export
        </.button>
      </.page_header>
      <.grid columns={%{sm: 1, lg: 2}} class="w-full">
        <.snapshot_form_panel snapshot={@snapshot} form={@form} />
        <.postgres_list snapshot={@snapshot} removals={@removals} />
        <.redis_list snapshot={@snapshot} removals={@removals} />
        <.jupyter_notebook_list snapshot={@snapshot} removals={@removals} />
        <.traditional_services_list snapshot={@snapshot} removals={@removals} />
        <.knative_services_list snapshot={@snapshot} removals={@removals} />
        <.ferretdb_list snapshot={@snapshot} removals={@removals} />
      </.grid>
    </.form>
    """
  end
end
