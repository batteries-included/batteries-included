defmodule ControlServerWeb.Projects.ImportSnapshotForm do
  @moduledoc false
  use ControlServerWeb, :live_component

  import ControlServerWeb.ProjectsSubcomponents

  alias CommonCore.Util.Memory
  alias KubeServices.ET.HomeBaseClient

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def update(%{data: data} = assigns, socket) do
    selected_id =
      get_in(data, [ControlServerWeb.Projects.ImportSelectSnapshotForm, "selected_snapshot_id"])

    {:ok,
     socket
     |> assign(:selected_snapshot_id, selected_id)
     |> assign(assigns)
     |> assign_snapshot()}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("submit", _params, socket) do
    send(self(), {:next, {__MODULE__, %{snapshot: socket.assigns.snapshot}}})
    {:noreply, socket}
  end

  defp assign_snapshot(%{assigns: %{selected_snapshot_id: snap_id}} = socket) when snap_id != nil and snap_id != "" do
    {:ok, snapshot} = HomeBaseClient.get_snapshot(snap_id)
    form = to_form(%{})

    socket
    |> assign(:snapshot, snapshot)
    |> assign(:form, form)
  end

  defp assign_snapshot(socket) do
    socket
    |> assign(:snapshot, nil)
    |> assign(:form, to_form(%{}))
  end

  defp title(nil), do: "No snapshot selected"

  defp title(snapshot) do
    "Importing snapshot: #{snapshot.name}"
  end

  defp postgres_clusters_list(assigns) do
    ~H"""
    <%= for {pg_cluster, _index} <- Enum.with_index(@snapshot.postgres_clusters) do %>
      <.h5>Postgres: {pg_cluster.name}</.h5>
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
    <% end %>
    """
  end

  def redis_list(assigns) do
    ~H"""
    <%= for {redis, _index} <- Enum.with_index(@snapshot.redis_instances) do %>
      <.h5>Redis: {redis.name}</.h5>
      <.data_list>
        <:item title="Memory Limits">
          {Memory.humanize(redis.memory_limits)}
        </:item>
        <:item title="Virtual Size">
          {CommonCore.Util.VirtualSize.get_virtual_size(redis)}
        </:item>
        <:item title="Num Instances">
          {redis.num_instances}
        </:item>
      </.data_list>
    <% end %>
    """
  end

  def ferretdb_list(assigns) do
    ~H"""
    <%= for {ferretdb, _index} <- Enum.with_index(@snapshot.ferret_services) do %>
      <.h5>FerretDB: {ferretdb.name}</.h5>
      <.data_list>
        <:item title="Memory Limits">
          {Memory.humanize(ferretdb.memory_limits)}
        </:item>
        <:item title="Virtual Size">
          {CommonCore.Util.VirtualSize.get_virtual_size(ferretdb)}
        </:item>
      </.data_list>
    <% end %>
    """
  end

  def jupyter_notebooks_list(assigns) do
    ~H"""
    <%= for {jupyter_notebook, _index} <- Enum.with_index(@snapshot.jupyter_notebooks) do %>
      <.h5>Jupyter Notebook: {jupyter_notebook.name}</.h5>
      <.data_list>
        <:item title="Memory Limits">
          {Memory.humanize(jupyter_notebook.memory_limits)}
        </:item>
        <:item title="Virtual Size">
          {CommonCore.Util.VirtualSize.get_virtual_size(jupyter_notebook)}
        </:item>
      </.data_list>
    <% end %>
    """
  end

  defp traditional_services_list(assigns) do
    ~H"""
    <%= for {service, _index} <- Enum.with_index(@snapshot.traditional_services) do %>
      <.h5>Traditional Service: {service.name}</.h5>
      <.data_list>
        <:item title="Memory Limits">
          {Memory.humanize(service.memory_limits)}
        </:item>
        <:item title="Virtual Size">
          {CommonCore.Util.VirtualSize.get_virtual_size(service)}
        </:item>
      </.data_list>
    <% end %>
    """
  end

  def knative_services_list(assigns) do
    ~H"""
    <%= for {service, _index} <- Enum.with_index(@snapshot.knative_services) do %>
      <.h5>Knative Service: {service.name}</.h5>
      <.data_list>
        <:item title="Memory Limits">
          {Memory.humanize(service.memory_limits)}
        </:item>
        <:item title="Virtual Size">
          {CommonCore.Util.VirtualSize.get_virtual_size(service)}
        </:item>
      </.data_list>
    <% end %>
    """
  end

  def model_instances_list(assigns) do
    ~H"""
    <%= for {model_instance, _index} <- Enum.with_index(@snapshot.model_instances) do %>
      <.h5>Model Instance: {model_instance.name}</.h5>
      <.data_list>
        <:item title="Model Name">
          {model_instance.model}
        </:item>
        <:item title="Virtual Size">
          {CommonCore.Util.VirtualSize.get_virtual_size(model_instance)}
        </:item>
      </.data_list>
    <% end %>
    """
  end

  defp empty_state(assigns) do
    ~H"""
    <.form
      id={"form_#{@id}"}
      class={@class}
      for={@form}
      phx-target={@myself}
      phx-change="validate"
      phx-submit="submit"
    >
      <.subform title="No snapshot selected">
        <p>
          No snapshot selected to import, skipping import step.
        </p>
      </.subform>
    </.form>
    """
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="contents">
      <.form
        :if={@snapshot != nil}
        for={@form}
        id={"form_#{@id}"}
        class={@class}
        phx-target={@myself}
        phx-change="validate"
        phx-submit="submit"
      >
        <.subform title={title(@snapshot)}>
          <.postgres_clusters_list snapshot={@snapshot} />
          <.redis_list snapshot={@snapshot} />
          <.ferretdb_list snapshot={@snapshot} />
          <.jupyter_notebooks_list snapshot={@snapshot} />
          <.traditional_services_list snapshot={@snapshot} />
          <.knative_services_list snapshot={@snapshot} />
          <.model_instances_list snapshot={@snapshot} />
        </.subform>
      </.form>

      <.empty_state
        :if={@snapshot == nil}
        id={"empty_state_#{@id}"}
        class={@class}
        myself={@myself}
        form={@form}
      />
    </div>
    """
  end
end
