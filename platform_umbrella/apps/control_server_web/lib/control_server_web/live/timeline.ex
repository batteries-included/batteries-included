defmodule ControlServerWeb.Live.Timeline do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias CommonCore.Timeline.BatteryInstall
  alias CommonCore.Timeline.Kube
  alias CommonCore.Timeline.NamedDatabase
  alias ControlServer.Timeline
  alias EventCenter.Database, as: DatabaseEventCenter
  alias Phoenix.Naming

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    :ok = DatabaseEventCenter.subscribe(:timeline_event)
    {:ok, assign(socket, :events, events())}
  end

  @impl Phoenix.LiveView
  def handle_info(_, socket) do
    {:noreply, assign(socket, :events, events())}
  end

  defp events do
    Timeline.list_timeline_events()
  end

  defp payload_container(assigns) do
    ~H"""
    <.flex column class="rounded-xl border-gray-lighter p-4 border">
      <%= render_slot(@inner_block) %>
    </.flex>
    """
  end

  defp payload_display(%{payload: %Kube{action: :delete}} = assigns) do
    ~H"""
    <.payload_container>
      <div class="text-black font-bold">
        Removed Kubernetes Resource
      </div>
      <div class="text-sm text-gray-darker">
        The <%= Naming.humanize(@payload.resource_type) %> resource <%= @payload.name %> was removed from <%= @payload.namespace %>.
      </div>
    </.payload_container>
    """
  end

  defp payload_display(%{payload: %Kube{action: :add}} = assigns) do
    ~H"""
    <.payload_container>
      <div class="text-black font-bold">
        Added Kubernetes Resource
      </div>
      <div class="text-sm text-gray-darker">
        The <%= Naming.humanize(@payload.resource_type) %> resource <%= @payload.name %> was
        added to <%= @payload.namespace %>.
      </div>
    </.payload_container>
    """
  end

  defp payload_display(%{payload: %Kube{action: :update}} = assigns) do
    ~H"""
    <.payload_container>
      <div class="text-black font-bold">
        Updated Kubernetes Resource
      </div>
      <div class="text-sm text-gray-darker">
        The <%= Naming.humanize(@payload.resource_type) %> resource <%= @payload.name %> was
        updated in <%= @payload.namespace %>. The new status
        is <%= Naming.humanize(@payload.computed_status) %>.
      </div>
    </.payload_container>
    """
  end

  defp payload_display(%{payload: %NamedDatabase{schema_type: :backend_service}} = assigns) do
    ~H"""
    <.payload_container>
      <div class="text-black font-bold">
        Backend Service <%= Naming.humanize(@payload.action) %>
      </div>

      <.data_list>
        <:item title="Show Backend Service">
          <.link navigate={~p(/backend_services)}><%= @payload.name %></.link>
        </:item>
      </.data_list>
    </.payload_container>
    """
  end

  defp payload_display(%{payload: %NamedDatabase{schema_type: :postgres_cluster}} = assigns) do
    ~H"""
    <.payload_container>
      <div class="text-black font-bold">
        Postgres Cluster <%= Naming.humanize(@payload.action) %>
      </div>

      <.data_list>
        <:item title="Show Cluster">
          <.link navigate={~p(/postgres/#{@payload.entity_id}/show)}><%= @payload.name %></.link>
        </:item>
        <:item title="Edit History">
          <.link navigate={~p(/postgres/#{@payload.entity_id}/edit_versions)}>Edit History</.link>
        </:item>
      </.data_list>
    </.payload_container>
    """
  end

  defp payload_display(%{payload: %NamedDatabase{schema_type: :knative_service}} = assigns) do
    ~H"""
    <.payload_container>
      <div class="text-black font-bold">
        Serverless <%= Naming.humanize(@payload.action) %>
      </div>

      <.data_list>
        <:item title="Show Service">
          <.link navigate={~p(/knative/services/#{@payload.entity_id}/show)}>
            <%= @payload.name %>
          </.link>
        </:item>
        <:item title="Edit History">
          <.link navigate={~p(/knative/services/#{@payload.entity_id}/edit_versions)}>
            Edit History
          </.link>
        </:item>
      </.data_list>
    </.payload_container>
    """
  end

  defp payload_display(%{payload: %NamedDatabase{schema_type: :ferret_service}} = assigns) do
    ~H"""
    <.payload_container>
      <div class="text-black font-bold">
        FerretDB/MongoDB <%= Naming.humanize(@payload.action) %>
      </div>

      <.data_list>
        <:item title="Show Service">
          <.link navigate={~p(/ferretdb/#{@payload.entity_id}/show)}><%= @payload.name %></.link>
        </:item>
        <:item title="Edit History">
          <.link navigate={~p(/ferretdb/#{@payload.entity_id}/edit_versions)}>Edit History</.link>
        </:item>
      </.data_list>
    </.payload_container>
    """
  end

  defp payload_display(%{payload: %BatteryInstall{}} = assigns) do
    ~H"""
    <.payload_container>
      <div class="text-black font-bold">
        New Battery Installed <%= Naming.humanize(@payload.battery_type) %>
      </div>
    </.payload_container>
    """
  end

  defp payload_display(assigns) do
    ~H"""
    <.flex column class="rounded-xl border-gray-lighter p-4 border">
      <pre class="text-sm overflow-x-auto">
        <%= inspect(@payload) %>
      </pre>
    </.flex>
    """
  end

  defp event_item(assigns) do
    ~H"""
    <.grid columns="12">
      <div class="text-2xl col-span-3 m-4">
        <.relative_display time={@event.inserted_at} />
      </div>
      <div class="col-span-9">
        <.payload_display payload={@event.payload} />
      </div>
    </.grid>
    """
  end

  @impl Phoenix.LiveView
  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <.page_header title="Timeline" back_link={~p"/magic"} />
    <.flex column class="rounded-xl border-gray-lighter dark:border-gray-darkest p-0 border">
      <.event_item :for={event <- @events} event={event} />
    </.flex>
    """
  end
end
