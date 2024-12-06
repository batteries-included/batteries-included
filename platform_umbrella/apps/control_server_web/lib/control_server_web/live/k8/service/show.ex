defmodule ControlServerWeb.Live.ServiceShow do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import CommonCore.Resources.FieldAccessors
  import ControlServerWeb.ResourceComponents

  alias EventCenter.KubeState, as: KubeEventCenter
  alias KubeServices.KubeState

  require Logger

  @resource_type :service

  @impl Phoenix.LiveView
  def mount(%{"name" => name, "namespace" => namespace}, _session, socket) do
    :ok = KubeEventCenter.subscribe(@resource_type)

    {:ok,
     socket
     |> assign_namespace(namespace)
     |> assign_name(name)
     |> assign_current_page()
     |> assign_resource(namespace, name)
     |> assign_endpoint(namespace, name)}
  end

  defp assign_namespace(socket, namespace) do
    assign(socket, namespace: namespace)
  end

  defp assign_name(socket, name) do
    assign(socket, name: name)
  end

  defp assign_current_page(socket) do
    assign(socket, current_page: :kubernetes)
  end

  defp assign_resource(socket, namespace, name) do
    resource = KubeState.get!(@resource_type, namespace, name)

    assign(socket,
      resource: resource,
      events: KubeState.get_events(resource),
      conditions: conditions(resource),
      status: status(resource),
      ports: ports(resource)
    )
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
    {:noreply,
     socket
     |> assign_resource(socket.assigns.namespace, socket.assigns.name)
     |> assign_endpoint(socket.assigns.namespace, socket.assigns.name)}
  end

  defp ports_panel(assigns) do
    ~H"""
    <.panel title="Ports">
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

  defp endpoint_panel(%{addresses: _} = assigns) do
    ~H"""
    <.panel variant="gray" title="Endpoint" class="lg:col-span-2">
      <.table :if={@addresses} id="endpoint-addresses-table" rows={@addresses}>
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

      <div :if={!@endpoint}>No Endpoint.</div>
    </.panel>
    """
  end

  defp endpoint_panel(assigns) do
    assigns
    |> assign_new(:addresses, fn ->
      assigns.endpoint
      |> Kernel.||(%{})
      |> Map.get("subsets", [])
      |> Kernel.||([])
      |> Enum.flat_map(&Map.get(&1, "addresses", []))
    end)
    |> endpoint_panel()
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

  defp details_panel(%{cluster_ips: _, lb_ips: _} = assigns) do
    ~H"""
    <.panel title="Details">
      <.data_list>
        <:item :if={@lb_ips && @lb_ips != []} title="Load Balancer IPs">
          {Enum.join(@lb_ips, ", ")}
        </:item>

        <:item :if={@cluster_ips} title="Cluster IPs">
          {Enum.join(@cluster_ips, ", ")}
        </:item>

        <:item title="IP Policy">
          {ip_family_policy(@resource)} {ip_families(@resource)}
        </:item>

        <:item title="Traffic Policy">
          {traffic_policy(@resource)}
        </:item>
      </.data_list>
    </.panel>
    """
  end

  defp details_panel(assigns) do
    assigns
    |> assign_new(:cluster_ips, fn %{resource: resource} = _assigns ->
      get_in(resource, ~w(spec clusterIPs)) || []
    end)
    |> assign_new(:lb_ips, fn %{resource: resource} = _assigns ->
      resource
      |> get_in(~w(status loadBalancer))
      |> Kernel.||(%{})
      |> Enum.flat_map(fn {_key, value} -> value end)
      |> Enum.map(&Map.get(&1, "ip"))
    end)
    |> details_panel()
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@name} back_link={~p"/kube/services"}>
      <.badge>
        <:item label="Namespace">{@namespace}</:item>
        <:item label="Started">
          <.relative_display time={get_in(@resource, ~w(metadata creationTimestamp))} />
        </:item>
      </.badge>
    </.page_header>

    <.grid columns={[sm: 1, lg: 2]}>
      <.ports_panel ports={@ports} />
      <.details_panel resource={@resource} />
      <.endpoint_panel :if={@endpoint != nil} endpoint={@endpoint} />
      <.label_panel resource={@resource} class="lg:col-span-2" />
      <.events_panel :if={@events} events={@events} class="lg:col-span-2" />
    </.grid>
    """
  end
end
