defmodule ControlServerWeb.Live.ResourceList do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import CommonUI.TabBar
  import ControlServerWeb.DeploymentsTable
  import ControlServerWeb.NodesTable
  import ControlServerWeb.PodsTable
  import ControlServerWeb.ServicesTable
  import ControlServerWeb.StatefulSetsTable

  alias EventCenter.KubeState, as: KubeEventCenter
  alias KubeServices.KubeState

  require Logger

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    live_action = socket.assigns.live_action
    subscribe(live_action)

    {:ok,
     socket
     |> assign(current_page: :kubernetes)
     |> assign_objects(objects(live_action))
     |> assign_page_title(title_text(live_action))}
  end

  def assign_page_title(socket, page_title) do
    assign(socket, page_title: page_title)
  end

  def assign_objects(socket, objects) do
    assign(socket, objects: objects)
  end

  defp subscribe(resource_type) do
    :ok = KubeEventCenter.subscribe(resource_type)
  end

  @impl Phoenix.LiveView
  def handle_info(_unused, socket) do
    {:noreply, assign_objects(socket, objects(socket.assigns.live_action))}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    {:noreply, assign_objects(socket, objects(socket.assigns.live_action))}
  end

  defp objects(type) do
    KubeState.get_all(type)
  end

  defp title_text(:deployment) do
    "Deployments"
  end

  defp title_text(:stateful_set) do
    "Stateful Sets"
  end

  defp title_text(:node) do
    "Nodes"
  end

  defp title_text(:pod) do
    "Pods"
  end

  defp title_text(:service) do
    "Services"
  end

  defp tabs(selected) do
    [
      {"Pods", ~p"/kube/pods", :pod == selected},
      {"Deployments", ~p"/kube/deployments", :deployment == selected},
      {"Stateful Sets", ~p"/kube/stateful_sets", :stateful_set == selected},
      {"Services", ~p"/kube/services", :service == selected},
      {"Nodes", ~p"/kube/nodes", :node == selected}
    ]
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title="Kubernetes" />
    <.tab_bar tabs={tabs(@live_action)} />
    <%= case @live_action do %>
      <% :deployment -> %>
        <.panel title="Deployments">
          <.deployments_table deployments={@objects} />
        </.panel>
      <% :stateful_set -> %>
        <.panel title="Stateful Sets">
          <.stateful_sets_table stateful_sets={@objects} />
        </.panel>
      <% :node -> %>
        <.panel title="Nodes">
          <.nodes_table nodes={@objects} />
        </.panel>
      <% :pod -> %>
        <.panel title="Pods">
          <.pods_table pods={@objects} />
        </.panel>
      <% :service -> %>
        <.panel title="Services">
          <.services_table services={@objects} />
        </.panel>
    <% end %>
    """
  end
end
