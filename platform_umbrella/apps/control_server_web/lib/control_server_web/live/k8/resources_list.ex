defmodule ControlServerWeb.Live.ResourceList do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.DeploymentsTable
  import ControlServerWeb.NodesTable
  import ControlServerWeb.PodsTable
  import ControlServerWeb.ServicesTable
  import ControlServerWeb.StatefulSetsTable

  alias CommonCore.Resources.FieldAccessors
  alias EventCenter.KubeState, as: KubeEventCenter
  alias KubeServices.KubeState

  require Logger

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    live_action = socket.assigns.live_action

    if connected?(socket) do
      :ok = KubeEventCenter.subscribe(live_action)
    end

    {:ok,
     socket
     |> assign(current_page: :kubernetes)
     |> assign_filter_value(nil)
     |> assign_objects()
     |> assign_page_title()}
  end

  defp assign_filter_value(socket, value) do
    assign(socket, filter_value: value)
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
    live_action = socket.assigns.live_action
    filter = String.downcase(socket.assigns.filter_value || "")

    assign_async(socket, types, fn ->
      {:ok,
       Enum.reduce(types, %{}, fn type, objects ->
         objs =
           type
           |> objects()
           |> Enum.filter(fn r ->
             # Keep the object if the filter is empty
             # or the downcased name
             #  contains the downcased filter.
             filter == "" ||
               r
               |> FieldAccessors.name()
               |> String.downcase()
               |> String.contains?(filter)
           end)

         Map.put(objects, type, type == live_action && objs)
       end)}
    end)
  end

  @impl Phoenix.LiveView
  def handle_info(_unused, socket) do
    {:noreply, socket |> assign_objects() |> assign_page_title()}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> assign_page_title()
     |> assign_filter_value(Map.get(params, "filter", ""))
     |> assign_objects()}
  end

  @impl Phoenix.LiveView
  def handle_event("filter_change", %{"filter_value" => value}, socket) do
    path = self_path(socket, value)
    {:noreply, push_patch(socket, to: path, replace: true)}
  end

  def handle_event("filter_change", %{"value" => value}, socket) do
    path = self_path(socket, value)
    {:noreply, push_patch(socket, to: path, replace: true)}
  end

  def handle_event("submit", _paylod, socket) do
    {:noreply, socket}
  end

  def self_path(socket, filter) do
    action = "#{socket.assigns.live_action}s"

    if filter == "" || filter == nil do
      "/kube/#{action}"
    else
      "/kube/#{action}?filter=#{filter}"
    end
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
    <.tab_bar variant="navigation">
      <:tab
        :for={{title, path, live_action} <- resource_tabs()}
        selected={@live_action == live_action}
        patch={path}
      >
        {title}
      </:tab>
    </.tab_bar>
    """
  end

  defp filter_form(assigns) do
    ~H"""
    <form phx-submit="submit">
      <.input
        name="filter_value"
        phx-change="filter_change"
        debounce="50"
        placeholder="Filter by name..."
        value={@value}
        autocomplete="off"
        autocapitalize="off"
      />
    </form>
    """
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.grid columns={[sm: 1, lg: 4]}>
      <.flex column class="lg:order-last">
        <.panel variant="gray">
          <.flex column>
            <.filter_form value={@filter_value} />
            <.tabs live_action={@live_action} />
          </.flex>
        </.panel>
      </.flex>
      <.panel title={@page_title} class="lg:col-span-3">
        <%= case @live_action do %>
          <% :deployment -> %>
            <.async_result :let={objects} assign={@deployment}>
              <:loading><.loader /></:loading>
              <.deployments_table deployments={objects} />
            </.async_result>
          <% :stateful_set -> %>
            <.async_result :let={objects} assign={@stateful_set}>
              <:loading><.loader /></:loading>
              <.stateful_sets_table stateful_sets={objects} />
            </.async_result>
          <% :node -> %>
            <.async_result :let={objects} assign={@node}>
              <:loading><.loader /></:loading>
              <.nodes_table nodes={objects} />
            </.async_result>
          <% :pod -> %>
            <.async_result :let={objects} assign={@pod}>
              <:loading><.loader /></:loading>
              <.pods_table pods={objects} />
            </.async_result>
          <% :service -> %>
            <.async_result :let={objects} assign={@service}>
              <:loading><.loader /></:loading>
              <.services_table services={objects} />
            </.async_result>
        <% end %>
      </.panel>
    </.grid>
    """
  end
end
