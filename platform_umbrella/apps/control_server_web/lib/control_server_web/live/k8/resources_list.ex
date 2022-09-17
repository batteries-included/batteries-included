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

  defp objects(:deployment) do
    KubeState.deployments()
  end

  defp objects(:stateful_set) do
    KubeState.stateful_sets()
  end

  defp objects(:node) do
    KubeState.nodes()
  end

  defp objects(:pod) do
    KubeState.pods()
  end

  defp objects(:service) do
    KubeState.services()
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

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title><%= title_text(@live_action) %></.title>
      </:title>
      <:left_menu>
        <.magic_menu active={"#{@live_action}"} />
      </:left_menu>
      <.body_section>
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
      </.body_section>
    </.layout>
    """
  end
end
