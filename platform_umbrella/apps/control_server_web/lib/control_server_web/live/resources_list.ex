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

  defp subscribe(:deployments) do
    :ok = KubeEventCenter.subscribe(:deployment)
  end

  defp subscribe(:stateful_sets) do
    :ok = KubeEventCenter.subscribe(:stateful_set)
  end

  defp subscribe(:nodes) do
    :ok = KubeEventCenter.subscribe(:node)
  end

  defp subscribe(:pods) do
    :ok = KubeEventCenter.subscribe(:pod)
  end

  defp subscribe(:services) do
    :ok = KubeEventCenter.subscribe(:service)
  end

  defp subscribe(_), do: nil

  @impl true
  def handle_info(_unused, socket) do
    {:noreply, assign(socket, :objects, objects(socket.assigns.live_action))}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, :objects, objects(socket.assigns.live_action))}
  end

  defp objects(:deployments) do
    KubeState.deployments()
  end

  defp objects(:stateful_sets) do
    KubeState.stateful_sets()
  end

  defp objects(:nodes) do
    KubeState.nodes()
  end

  defp objects(:pods) do
    KubeState.pods()
  end

  defp objects(:services) do
    KubeState.services()
  end

  defp title_text(:deployments) do
    "Deployments"
  end

  defp title_text(:stateful_sets) do
    "Stateful Sets"
  end

  defp title_text(:nodes) do
    "Nodes"
  end

  defp title_text(:pods) do
    "Pods"
  end

  defp title_text(:services) do
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
          <% :deployments -> %>
            <.deployments_display deployments={@objects} />
          <% :stateful_sets -> %>
            <.stateful_sets_display stateful_sets={@objects} />
          <% :nodes -> %>
            <.nodes_display nodes={@objects} />
          <% :pods -> %>
            <.pods_display pods={@objects} />
          <% :services -> %>
            <.services_display services={@objects} />
        <% end %>
      </.body_section>
    </.layout>
    """
  end
end
