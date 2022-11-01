defmodule ControlServerWeb.Live.ResourceList do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout
  import ControlServerWeb.DeploymentsDisplay
  import ControlServerWeb.StatefulSetsDisplay
  import ControlServerWeb.NodesDisplay
  import ControlServerWeb.ServicesDisplay
  import ControlServerWeb.PodsDisplay
  import CommonUI.TabBar

  alias EventCenter.KubeState, as: KubeEventCenter
  alias KubeExt.KubeState

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    live_action = socket.assigns.live_action
    subscribe(live_action)

    {:ok, assign(socket, :objects, objects(live_action))}
  end

  defp subscribe(resource_type) do
    :ok = KubeEventCenter.subscribe(resource_type)
  end

  @impl true
  def handle_info(_unused, socket) do
    {:noreply, assign(socket, :objects, objects(socket.assigns.live_action))}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, :objects, objects(socket.assigns.live_action))}
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

  @impl true
  def render(assigns) do
    ~H"""
    <.layout group={:magic} active={:kube_resources}>
      <:title>
        <.title><%= title_text(@live_action) %></.title>
      </:title>
      <.tab_bar tabs={tabs(@live_action)} />
      <%= case @live_action do %>
        <% :deployment -> %>
          <.deployments_display deployments={@objects} />
        <% :stateful_set -> %>
          <.stateful_sets_display stateful_sets={@objects} />
        <% :node -> %>
          <.nodes_display nodes={@objects} />
        <% :pod -> %>
          <.pods_display pods={@objects} />
        <% :service -> %>
          <.services_display services={@objects} />
      <% end %>
    </.layout>
    """
  end
end
