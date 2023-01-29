defmodule ControlServerWeb.Live.ResourceList do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ControlServerWeb, {:live_view, layout: :fresh}

  import ControlServerWeb.DeploymentsTable
  import ControlServerWeb.StatefulSetsTable
  import ControlServerWeb.NodesTable
  import ControlServerWeb.ServicesTable
  import ControlServerWeb.PodsTable
  import CommonUI.TabBar

  alias EventCenter.KubeState, as: KubeEventCenter
  alias KubeExt.KubeState

  require Logger

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    live_action = socket.assigns.live_action
    subscribe(live_action)

    {:ok,
     socket
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
    <.tab_bar tabs={tabs(@live_action)} />
    <%= case @live_action do %>
      <% :deployment -> %>
        <.deployments_table deployments={@objects} />
      <% :stateful_set -> %>
        <.stateful_sets_table stateful_sets={@objects} />
      <% :node -> %>
        <.nodes_table nodes={@objects} />
      <% :pod -> %>
        <.pods_table pods={@objects} />
      <% :service -> %>
        <.services_table services={@objects} />
    <% end %>
    """
  end
end
