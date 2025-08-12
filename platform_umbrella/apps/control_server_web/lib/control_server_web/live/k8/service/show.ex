defmodule ControlServerWeb.Live.ServiceShow do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import CommonCore.Resources.FieldAccessors
  import ControlServerWeb.ResourceComponents
  import ControlServerWeb.ResourceHTMLHelper

  alias EventCenter.KubeState, as: KubeEventCenter
  alias KubeServices.KubeState

  require Logger

  @resource_type :service

  @impl Phoenix.LiveView
  def mount(%{"name" => name, "namespace" => namespace}, _session, socket) do
    if connected?(socket) do
      :ok = KubeEventCenter.subscribe(@resource_type)
    end

    {:ok,
     socket
     |> assign(
       current_page: :kubernetes,
       namespace: namespace,
       name: name
     )
     |> assign_resource()}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _uri, %{assigns: %{live_action: :events}} = socket) do
    {:noreply, assign_events(socket)}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  defp assign_events(%{assigns: %{resource: resource, live_action: :events}} = socket) do
    events = KubeState.get_events(resource)
    assign(socket, events: events)
  end

  defp assign_events(socket), do: socket

  defp assign_resource(%{assigns: %{name: name, namespace: namespace}} = socket) do
    resource = KubeState.get!(@resource_type, namespace, name)

    socket
    |> assign(
      resource: resource,
      events: KubeState.get_events(resource),
      conditions: conditions(resource),
      status: status(resource),
      ports: ports(resource)
    )
    |> assign_endpoint(namespace, name)
  end

  defp assign_endpoint(socket, namespace, name) do
    case KubeState.get(:endpoint, namespace, name) do
      {:ok, %{} = endpoint} ->
        assign(socket, endpoint: endpoint)

      _ ->
        Logger.debug("No endpoint found for #{namespace} #{name}")
        assign(socket, endpoint: nil)
    end
  end

  @impl Phoenix.LiveView
  def handle_info(_unused, socket) do
    # re-fetch the resources
    {:noreply, assign_resource(socket)}
  end

  attr :resource, :map
  attr :namespace, :string

  def service_facts_section(%{} = assigns) do
    ~H"""
    <.badge>
      <:item label="Namespace">{@namespace}</:item>
      <:item label="Started">
        <.relative_display time={creation_timestamp(@resource)} />
      </:item>
    </.badge>
    """
  end

  defp link_panel(assigns) do
    ~H"""
    <.panel variant="gray" class="lg:order-last">
      <.tab_bar variant="navigation">
        <:tab selected={@live_action == :index} patch={resource_path(@resource)}>Overview</:tab>
        <:tab selected={@live_action == :events} patch={resource_path(@resource, :events)}>
          Events
        </:tab>
        <:tab selected={@live_action == :endpoints} patch={resource_path(@resource, :endpoints)}>
          Endpoints
        </:tab>
        <:tab selected={@live_action == :labels} patch={resource_path(@resource, :labels)}>
          Labels
        </:tab>
        <:tab selected={@live_action == :annotations} patch={resource_path(@resource, :annotations)}>
          Annotations
        </:tab>
        <:tab navigate={raw_resource_path(@resource)}>Raw</:tab>
      </.tab_bar>
    </.panel>
    """
  end

  defp ip_family_policy(resource) do
    get_in(resource, ~w(spec ipFamilyPolicy))
  end

  defp ip_families(resource) do
    resource |> get_in(~w(spec ipFamilies)) |> Kernel.||([]) |> Enum.join(", ")
  end

  defp traffic_policy(resource) do
    get_in(resource, ~w(spec internalTrafficPolicy))
  end

  defp main_page(assigns) do
    ~H"""
    <.page_header title={@name} back_link={~p"/kube/services"}>
      <.service_facts_section resource={@resource} namespace={@namespace} />
    </.page_header>

    <.grid columns={[sm: 1, lg: 4]} class="lg:template-rows-3">
      <.link_panel live_action={@live_action} resource={@resource} />
      <.panel title="Details" class="lg:col-span-3">
        <.data_list>
          <:item :if={cluster_ips(@resource) != []} title="Cluster IPs">
            {Enum.join(cluster_ips(@resource), ", ")}
          </:item>

          <:item :if={lb_ips(@resource) != []} title="Load Balancer IPs">
            {Enum.join(lb_ips(@resource), ", ")}
          </:item>

          <:item title="IP Policy">
            {ip_family_policy(@resource)} {ip_families(@resource)}
          </:item>

          <:item title="Traffic Policy">
            {traffic_policy(@resource)}
          </:item>
        </.data_list>
      </.panel>
    </.grid>
    <.panel title="Ports" class="mt-8">
      <.table :if={@ports} id="ports-table" rows={@ports}>
        <:col :let={port} label="Name">{Map.get(port, "name", "")}</:col>
        <:col :let={port} label="Port">{Map.get(port, "port", "")}</:col>
        <:col :let={port} label="Target Port">{Map.get(port, "targetPort", "")}</:col>
        <:col :let={port} label="Protocol">{Map.get(port, "protocol", "")}</:col>
      </.table>

      <div :if={@ports == []}>No ports.</div>
    </.panel>
    """
  end

  defp endpoints_page(assigns) do
    ~H"""
    <.page_header title={@name} back_link={resource_path(@resource)}>
      <.service_facts_section resource={@resource} namespace={@namespace} />
    </.page_header>

    <.grid columns={%{sm: 1, lg: 4}} class="lg:template-rows-2">
      <.link_panel live_action={@live_action} resource={@resource} />

      <.panel title="Endpoints" class="lg:col-span-3 lg:row-span-2">
        <div :if={@endpoint != nil}>
          <.table
            :if={endpoint_addresses(@endpoint) != []}
            id="endpoint-addresses-table"
            rows={endpoint_addresses(@endpoint)}
          >
            <:col :let={address} label="Address">{Map.get(address, "ip", "")}</:col>
            <:col :let={address} label="Node Name">{Map.get(address, "nodeName", "")}</:col>
            <:col :let={address} label="Target Kind">
              {Map.get(address, "targetRef", %{}) |> Map.get("kind", "")}
            </:col>
            <:col :let={address} label="Target Name">
              {Map.get(address, "targetRef", %{}) |> Map.get("name", "")}
            </:col>
            <:col :let={address} label="Target Namespace">
              {Map.get(address, "targetRef", %{}) |> Map.get("namespace", "")}
            </:col>
          </.table>
          <div :if={endpoint_addresses(@endpoint) == []} class="text-center text-gray-500 p-4">
            No addresses found in this endpoint.
          </div>
        </div>
        <div :if={@endpoint == nil} class="text-center text-gray-500 p-4">
          No endpoint found for this service.
        </div>
      </.panel>
    </.grid>
    """
  end

  defp events_page(assigns) do
    ~H"""
    <.page_header title={@name} back_link={resource_path(@resource)}>
      <.service_facts_section resource={@resource} namespace={@namespace} />
    </.page_header>

    <.grid columns={%{sm: 1, lg: 4}} class="lg:template-rows-2">
      <.link_panel live_action={@live_action} resource={@resource} />
      <.events_panel events={@events} class="lg:col-span-3 lg:row-span-2" />
    </.grid>
    """
  end

  defp labels_page(assigns) do
    ~H"""
    <.page_header title={@name} back_link={resource_path(@resource)}>
      <.service_facts_section resource={@resource} namespace={@namespace} />
    </.page_header>

    <.grid columns={%{sm: 1, lg: 4}} class="lg:template-rows-2">
      <.link_panel live_action={@live_action} resource={@resource} />

      <.panel title="Labels" class="lg:col-span-3 lg:row-span-2">
        <.data_list>
          <:item :for={{key, value} <- labels(@resource)} title={key}>
            <.truncate_tooltip value={value} />
          </:item>
        </.data_list>
      </.panel>
    </.grid>
    """
  end

  defp annotations_page(assigns) do
    ~H"""
    <.page_header title={@name} back_link={resource_path(@resource)}>
      <.service_facts_section resource={@resource} namespace={@namespace} />
    </.page_header>

    <.grid columns={%{sm: 1, lg: 4}} class="lg:template-rows-2">
      <.link_panel live_action={@live_action} resource={@resource} />
      <.panel title="Annotations" class="lg:col-span-3 lg:row-span-2">
        <.data_list>
          <:item :for={{key, value} <- annotations(@resource)} title={key}>
            <%!--
            We have to truncate a lot here since
            annotations can be huge and we don't want to inflate page size
            --%>
            <.truncate_tooltip value={truncate(value, length: 256)} />
          </:item>
        </.data_list>
      </.panel>
    </.grid>
    """
  end

  defp cluster_ips(resource) do
    get_in(resource, ~w(spec clusterIPs)) || []
  end

  @spec lb_ips(map()) :: [String.t()]
  defp lb_ips(resource) do
    resource
    |> get_in(~w(status loadBalancer))
    |> Kernel.||(%{})
    |> Enum.flat_map(fn {_key, value} -> value end)
    |> Enum.map(&Map.get(&1, "ip"))
  end

  defp endpoint_addresses(endpoint) do
    endpoint
    |> Kernel.||(%{})
    |> Map.get("subsets", [])
    |> Kernel.||([])
    |> Enum.flat_map(&Map.get(&1, "addresses", []))
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <%= case @live_action do %>
      <% :index -> %>
        <.main_page {assigns} />
      <% :events -> %>
        <.events_page {assigns} />
      <% :endpoints -> %>
        <.endpoints_page {assigns} />
      <% :labels -> %>
        <.labels_page {assigns} />
      <% :annotations -> %>
        <.annotations_page {assigns} />
      <% _ -> %>
        {@live_action}
    <% end %>
    """
  end
end
