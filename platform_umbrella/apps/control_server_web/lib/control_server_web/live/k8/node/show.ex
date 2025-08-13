defmodule ControlServerWeb.Live.NodeShow do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import CommonCore.Resources.FieldAccessors
  import ControlServerWeb.ConditionsDisplay
  import ControlServerWeb.PodsTable
  import ControlServerWeb.ResourceComponents
  import ControlServerWeb.ResourceHTMLHelper

  alias CommonCore.Util.Memory
  alias EventCenter.KubeState, as: KubeEventCenter
  alias KubeServices.KubeState
  alias KubeServices.SystemState.SummaryBatteries
  alias KubeServices.SystemState.SummaryURLs

  require Logger

  @resource_type :node

  @impl Phoenix.LiveView
  def mount(%{"name" => name}, _session, socket) do
    if connected?(socket) do
      :ok = KubeEventCenter.subscribe(@resource_type)
    end

    {:ok,
     socket
     |> assign(
       current_page: :kubernetes,
       name: name
     )
     |> assign_batteries_enabled()
     |> assign_resource()
     |> assign_grafana_dashboard()}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _uri, %{assigns: %{live_action: :events}} = socket) do
    {:noreply, assign_events(socket)}
  end

  def handle_params(_params, _uri, %{assigns: %{live_action: :pods}} = socket) do
    {:noreply, assign_pods(socket)}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _uri, socket) do
    {:noreply, assign_events(socket)}
  end

  @impl Phoenix.LiveView
  def handle_info(_unused, socket) do
    # re-fetch the resources from state table
    {:noreply, assign_resource(socket)}
  end

  defp assign_resource(%{assigns: %{name: name}} = socket) do
    # Nodes are global resources, so no namespace
    assign(socket, resource: KubeState.get!(@resource_type, nil, name))
  end

  defp assign_events(%{assigns: %{resource: resource, live_action: :events}} = socket) do
    events = KubeState.get_events(resource)
    assign(socket, events: events)
  end

  defp assign_events(socket), do: socket

  defp assign_pods(%{assigns: %{resource: resource, live_action: :pods}} = socket) do
    # Get all pods that are scheduled on this node
    node_name = name(resource)
    all_pods = KubeState.get_all(:pod)

    node_pods =
      Enum.filter(all_pods, fn pod ->
        node_name(pod) == node_name
      end)

    assign(socket, pods: node_pods)
  end

  defp assign_pods(socket), do: socket

  defp assign_batteries_enabled(socket) do
    assign(socket,
      grafana_enabled: SummaryBatteries.batteries_installed(~w(grafana kube_monitoring)a)
    )
  end

  defp assign_grafana_dashboard(%{assigns: %{resource: resource}} = socket) do
    url =
      if SummaryBatteries.batteries_installed(~w(grafana kube_monitoring)a) do
        SummaryURLs.node_dashboard_url(resource)
      end

    assign(socket, grafana_dashboard_url: url)
  end

  # Node-specific field accessors
  defp node_addresses(resource) do
    get_in(resource, ~w(status addresses)) || []
  end

  defp node_capacity(resource) do
    get_in(resource, ~w(status capacity)) || %{}
  end

  defp node_allocatable(resource) do
    get_in(resource, ~w(status allocatable)) || %{}
  end

  defp node_info(resource) do
    get_in(resource, ~w(status nodeInfo)) || %{}
  end

  defp node_ready?(resource) do
    resource
    |> conditions()
    |> Enum.find(%{}, fn condition ->
      Map.get(condition, "type") == "Ready"
    end)
    |> Map.get("status") == "True"
  end

  attr :resource, :map

  def node_facts_section(%{} = assigns) do
    ~H"""
    <.badge>
      <:item label="Status">
        <.status_icon status={node_ready?(@resource)} />
      </:item>
      <:item label="Created">
        <.relative_display time={creation_timestamp(@resource)} />
      </:item>
    </.badge>
    """
  end

  def node_addresses_section(assigns) do
    assigns = assign(assigns, :addresses, node_addresses(assigns.resource))

    ~H"""
    <.panel title="Network Addresses" class="col-span-2">
      <.data_list>
        <:item :for={address <- @addresses} title={Map.get(address, "type", "Unknown")}>
          {Map.get(address, "address", "")}
        </:item>
      </.data_list>
    </.panel>
    """
  end

  def node_capacity_section(assigns) do
    assigns = assign_new(assigns, :capacity, fn -> node_capacity(assigns.resource) end)
    assigns = assign_new(assigns, :allocatable, fn -> node_allocatable(assigns.resource) end)

    ~H"""
    <.panel title="Resource Capacity" class="col-span-2">
      <.grid columns={%{sm: 1, lg: 2}}>
        <.data_list>
          <h4 class="text-sm font-semibold text-gray-900 mb-2">Capacity</h4>
          <:item title="CPU">{Map.get(@capacity, "cpu", "N/A")}</:item>
          <:item title="Memory">
            {Memory.humanize(Memory.to_bytes(Map.get(@capacity, "memory", "0")))}
          </:item>
          <:item title="Ephemeral Storage">
            {Memory.humanize(Memory.to_bytes(Map.get(@capacity, "ephemeral-storage", "0")))}
          </:item>
          <:item title="Pods">{Map.get(@capacity, "pods", "N/A")}</:item>
        </.data_list>

        <.data_list>
          <h4 class="text-sm font-semibold text-gray-900 mb-2">Allocatable</h4>
          <:item title="CPU">{Map.get(@allocatable, "cpu", "N/A")}</:item>
          <:item title="Memory">
            {Memory.humanize(Memory.to_bytes(Map.get(@allocatable, "memory", "0")))}
          </:item>
          <:item title="Ephemeral Storage">
            {Memory.humanize(Memory.to_bytes(Map.get(@allocatable, "ephemeral-storage", "0")))}
          </:item>
          <:item title="Pods">{Map.get(@allocatable, "pods", "N/A")}</:item>
        </.data_list>
      </.grid>
    </.panel>
    """
  end

  def node_system_info_section(assigns) do
    assigns = assign(assigns, :node_info, node_info(assigns.resource))

    ~H"""
    <.panel title="System Information" class="col-span-2">
      <.grid columns={%{sm: 1, lg: 2}}>
        <.data_list>
          <:item title="Operating System">{Map.get(@node_info, "osImage", "N/A")}</:item>
          <:item title="Architecture">{Map.get(@node_info, "architecture", "N/A")}</:item>
          <:item title="Kernel Version">{Map.get(@node_info, "kernelVersion", "N/A")}</:item>
          <:item title="Container Runtime">
            {Map.get(@node_info, "containerRuntimeVersion", "N/A")}
          </:item>
        </.data_list>

        <.data_list>
          <:item title="Kubelet Version">{Map.get(@node_info, "kubeletVersion", "N/A")}</:item>
          <:item title="Kube Proxy Version">{Map.get(@node_info, "kubeProxyVersion", "N/A")}</:item>
          <:item title="Machine ID">{Map.get(@node_info, "machineID", "N/A")}</:item>
          <:item title="System UUID">{Map.get(@node_info, "systemUUID", "N/A")}</:item>
        </.data_list>
      </.grid>
    </.panel>
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
        <:tab selected={@live_action == :pods} patch={resource_path(@resource, :pods)}>
          Pods
        </:tab>
        <:tab selected={@live_action == :labels} patch={resource_path(@resource, :labels)}>
          Labels
        </:tab>
        <:tab selected={@live_action == :annotations} patch={resource_path(@resource, :annotations)}>
          Annotations
        </:tab>
        <:tab navigate={raw_resource_path(@resource)}>Raw</:tab>
      </.tab_bar>
      <.a :if={@grafana_dashboard_url != nil} variant="bordered" href={@grafana_dashboard_url}>
        Grafana Dashboard
      </.a>
    </.panel>
    """
  end

  defp main_page(assigns) do
    ~H"""
    <.page_header title={@name} back_link={~p"/kube/nodes"}>
      <.node_facts_section resource={@resource} />
    </.page_header>

    <.flex column>
      <.grid columns={[sm: 1, lg: 4]} class="lg:template-rows-2">
        <.link_panel
          live_action={@live_action}
          resource={@resource}
          grafana_dashboard_url={@grafana_dashboard_url}
        />
        <.panel title="Node Details" class="lg:col-span-3 lg:row-span-2">
          <.data_list>
            <:item title="Ready Status">
              <.status_icon status={node_ready?(@resource)} />
            </:item>
            <:item :if={get_in(@resource, ~w(spec podCIDR))} title="Pod CIDR">
              {get_in(@resource, ~w(spec podCIDR))}
            </:item>
            <:item :if={get_in(@resource, ~w(spec providerID))} title="Provider ID">
              {get_in(@resource, ~w(spec providerID))}
            </:item>
          </.data_list>
        </.panel>
      </.grid>

      <.node_addresses_section resource={@resource} />
      <.node_capacity_section resource={@resource} />
      <.node_system_info_section resource={@resource} />
      <.conditions_display conditions={conditions(@resource)} />
    </.flex>
    """
  end

  defp events_page(assigns) do
    ~H"""
    <.page_header title={@name} back_link={resource_path(@resource)}>
      <.node_facts_section resource={@resource} />
    </.page_header>

    <.grid columns={%{sm: 1, lg: 4}} class="lg:template-rows-2">
      <.link_panel
        live_action={@live_action}
        resource={@resource}
        grafana_dashboard_url={@grafana_dashboard_url}
      />
      <.events_panel events={@events} class="lg:col-span-3 lg:row-span-2" />
    </.grid>
    """
  end

  defp pods_page(assigns) do
    ~H"""
    <.page_header title={@name} back_link={resource_path(@resource)}>
      <.node_facts_section resource={@resource} />
    </.page_header>

    <.grid columns={%{sm: 1, lg: 4}} class="lg:template-rows-2">
      <.link_panel
        live_action={@live_action}
        resource={@resource}
        grafana_dashboard_url={@grafana_dashboard_url}
      />
      <.panel title="Pods on this Node" class="lg:col-span-3 lg:row-span-2">
        <.pods_table pods={@pods} />
      </.panel>
    </.grid>
    """
  end

  defp labels_page(assigns) do
    ~H"""
    <.page_header title={@name} back_link={resource_path(@resource)}>
      <.node_facts_section resource={@resource} />
    </.page_header>

    <.grid columns={%{sm: 1, lg: 4}} class="lg:template-rows-2">
      <.link_panel
        live_action={@live_action}
        resource={@resource}
        grafana_dashboard_url={@grafana_dashboard_url}
      />

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
      <.node_facts_section resource={@resource} />
    </.page_header>

    <.grid columns={%{sm: 1, lg: 4}} class="lg:template-rows-2">
      <.link_panel
        live_action={@live_action}
        resource={@resource}
        grafana_dashboard_url={@grafana_dashboard_url}
      />
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

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <%= case @live_action do %>
      <% :index -> %>
        <.main_page {assigns} />
      <% :events -> %>
        <.events_page {assigns} />
      <% :pods -> %>
        <.pods_page {assigns} />
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
