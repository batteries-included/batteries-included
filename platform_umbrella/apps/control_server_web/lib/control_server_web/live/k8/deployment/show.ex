defmodule ControlServerWeb.Live.DeploymentShow do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import CommonCore.Resources.FieldAccessors
  import ControlServerWeb.ConditionsDisplay
  import ControlServerWeb.PodsTable
  import ControlServerWeb.ResourceComponents
  import ControlServerWeb.ResourceHTMLHelper

  alias EventCenter.KubeState, as: KubeEventCenter
  alias KubeServices.KubeState

  require Logger

  @resource_type :deployment

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
     |> assign_resource()
     |> assign_subresources()}
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
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info(_unused, socket) do
    # re-fetch the resources
    {:noreply,
     socket
     |> assign_resource()
     |> assign_subresources()}
  end

  defp assign_resource(%{assigns: %{name: name, namespace: namespace}} = socket) do
    assign(socket, resource: get_resource!(namespace, name))
  end

  defp assign_subresources(%{assigns: %{resource: resource}} = socket) do
    replicasets = KubeState.get_owned_resources(:replicaset, resource)

    assign(socket,
      replicasets: replicasets,
      conditions: conditions(resource),
      status: status(resource)
    )
  end

  defp assign_events(%{assigns: %{resource: resource, live_action: :events}} = socket) do
    events = KubeState.get_events(resource)
    assign(socket, events: events)
  end

  defp assign_events(socket), do: socket

  defp assign_pods(%{assigns: %{replicasets: replicasets, live_action: :pods}} = socket) do
    pods = Enum.flat_map(replicasets, fn rs -> KubeState.get_owned_resources(:pod, rs) end)
    assign(socket, pods: pods)
  end

  defp assign_pods(socket), do: socket

  defp get_resource!(namespace, name) do
    KubeState.get!(@resource_type, namespace, name)
  end

  def deployment_facts_section(%{} = assigns) do
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
    </.panel>
    """
  end

  defp main_page(assigns) do
    ~H"""
    <.page_header title={@name} back_link={~p"/kube/deployments"}>
      <.deployment_facts_section resource={@resource} namespace={@namespace} />
    </.page_header>

    <.flex column>
      <.grid columns={[sm: 1, lg: 4]} class="lg:template-rows-2">
        <.link_panel live_action={@live_action} resource={@resource} />
        <.panel title="Details" class="lg:col-span-3 lg:row-span-2">
          <.data_list id="status">
            <:item title="Total Replicas">{Map.get(@status, "replicas", 0)}</:item>
            <:item title="Available Replicas">{Map.get(@status, "availableReplicas", 0)}</:item>
            <:item title="Ready Replicas">{Map.get(@status, "readyReplicas", 0)}</:item>
            <:item title="Observed Generation">{Map.get(@status, "observedGeneration", 0)}</:item>
          </.data_list>
        </.panel>
      </.grid>

      <.conditions_display conditions={@conditions} />
    </.flex>
    """
  end

  defp events_page(assigns) do
    ~H"""
    <.page_header title={@name} back_link={resource_path(@resource)}>
      <.deployment_facts_section resource={@resource} namespace={@namespace} />
    </.page_header>

    <.grid columns={%{sm: 1, lg: 4}} class="lg:template-rows-2">
      <.link_panel live_action={@live_action} resource={@resource} />
      <.events_panel events={@events} class="lg:col-span-3 lg:row-span-2" />
    </.grid>
    """
  end

  defp pods_page(assigns) do
    ~H"""
    <.page_header title={@name} back_link={resource_path(@resource)}>
      <.deployment_facts_section resource={@resource} namespace={@namespace} />
    </.page_header>

    <.grid columns={%{sm: 1, lg: 4}} class="lg:template-rows-2">
      <.link_panel live_action={@live_action} resource={@resource} />
      <.panel title="Pods" class="lg:col-span-3 lg:row-span-2">
        <.pods_table pods={@pods} />
      </.panel>
    </.grid>
    """
  end

  defp labels_page(assigns) do
    ~H"""
    <.page_header title={@name} back_link={resource_path(@resource)}>
      <.deployment_facts_section resource={@resource} namespace={@namespace} />
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
      <.deployment_facts_section resource={@resource} namespace={@namespace} />
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
