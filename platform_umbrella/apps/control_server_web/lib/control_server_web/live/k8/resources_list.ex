defmodule ControlServerWeb.Live.ResourceList do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.DeploymentsTable
  import ControlServerWeb.Loader
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
     |> assign_objects()
     |> assign_page_title()}
  end

  def assign_page_title(socket) do
    assign(socket, page_title: title_text(socket.assigns.live_action))
  end

  def assign_objects(socket) do
    types = [:deployment, :stateful_set, :node, :pod, :service]

    # So real shit here.
    #
    # Every once in a while tables will fail to render silently.
    # Thats because render will be called before the table data
    # has finished loading but we still have the last data....
    # To work around that every kube type we have a display
    # for has it's on lists.
    assign_async(socket, types, fn ->
      {:ok,
       Enum.reduce(types, %{}, fn type, objects ->
         Map.put(objects, type, type == socket.assigns.live_action && objects(type))
       end)}
    end)
  end

  defp subscribe(resource_type) do
    :ok = KubeEventCenter.subscribe(resource_type)
  end

  @impl Phoenix.LiveView
  def handle_info(_unused, socket) do
    {:noreply, socket |> assign_objects() |> assign_page_title()}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    {:noreply,
     socket
     |> assign_objects()
     |> assign_page_title()}
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

  @resource_tabs [
    {"Pods", "/kube/pods", :pod},
    {"Deployments", "/kube/deployments", :deployment},
    {"Stateful Sets", "/kube/stateful_sets", :stateful_set},
    {"Services", "/kube/services", :service},
    {"Nodes", "/kube/nodes", :node}
  ]

  defp resource_tabs, do: @resource_tabs

  defp tabs(assigns) do
    ~H"""
    <.tab_bar>
      <:tab
        :for={{title, path, live_action} <- resource_tabs()}
        selected={@live_action == live_action}
        patch={path}
      >
        <%= title %>
      </:tab>
    </.tab_bar>
    """
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title="Kubernetes" />
    <.tabs live_action={@live_action} />

    <%= case @live_action do %>
      <% :deployment -> %>
        <.panel title="Deployments">
          <.async_result :let={objects} assign={@deployment}>
            <:loading><.loader /></:loading>
            <.deployments_table deployments={objects} />
          </.async_result>
        </.panel>
      <% :stateful_set -> %>
        <.panel title="Stateful Sets">
          <.async_result :let={objects} assign={@stateful_set}>
            <:loading><.loader /></:loading>
            <.stateful_sets_table stateful_sets={objects} />
          </.async_result>
        </.panel>
      <% :node -> %>
        <.panel title="Nodes">
          <.async_result :let={objects} assign={@node}>
            <:loading><.loader /></:loading>
            <.nodes_table nodes={objects} />
          </.async_result>
        </.panel>
      <% :pod -> %>
        <.panel title="Pods">
          <.async_result :let={objects} assign={@pod}>
            <:loading><.loader /></:loading>
            <.pods_table pods={objects} />
          </.async_result>
        </.panel>
      <% :service -> %>
        <.panel title="Services">
          <.async_result :let={objects} assign={@service}>
            <:loading><.loader /></:loading>
            <.services_table services={objects} />
          </.async_result>
        </.panel>
    <% end %>
    """
  end
end
