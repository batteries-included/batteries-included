defmodule ControlServerWeb.Live.FerretServiceShow do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import CommonCore.Resources.FieldAccessors
  import ControlServerWeb.Audit.EditVersionsTable
  import ControlServerWeb.PodsTable

  alias ControlServer.FerretDB
  alias KubeServices.KubeState

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign_page_title(socket)}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _, socket) do
    service = FerretDB.get_ferret_service!(id)

    {:noreply,
     socket
     |> assign_page_title()
     |> assign_current_page()
     |> assign_ferret_service(service)
     |> assign_pods()
     |> maybe_assign_edit_versions()}
  end

  defp assign_current_page(socket) do
    assign(socket, current_page: :data)
  end

  defp assign_page_title(%{assigns: %{live_action: :show}} = socket) do
    assign(socket, page_title: "Show Ferret Service")
  end

  defp assign_page_title(%{assigns: %{live_action: :edit_versions}} = socket) do
    assign(socket, page_title: "Ferret Service: Edit History")
  end

  defp assign_pods(%{assigns: %{ferret_service: ferret_service}} = socket) do
    pods =
      :pod
      |> KubeState.get_all()
      |> Enum.filter(fn pod -> ferret_service.id == labeled_owner(pod) end)

    assign(socket, pods: pods)
  end

  defp assign_ferret_service(socket, ferret_service) do
    assign(socket, ferret_service: ferret_service)
  end

  defp maybe_assign_edit_versions(%{assigns: %{ferret_service: ferret_service, live_action: live_action}} = socket)
       when live_action == :edit_versions do
    assign(socket, :edit_versions, ControlServer.Audit.history(ferret_service))
  end

  defp maybe_assign_edit_versions(socket), do: socket

  @impl Phoenix.LiveView
  def handle_event("delete", _, socket) do
    {:ok, _} = FerretDB.delete_ferret_service(socket.assigns.ferret_service)

    {:noreply, push_redirect(socket, to: ~p"/ferretdb")}
  end

  defp edit_url(ferret_service), do: ~p"/ferretdb/#{ferret_service}/edit"
  defp show_url(ferret_service), do: ~p"/ferretdb/#{ferret_service}/show"
  defp edit_versions_url(ferret_service), do: ~p"/ferretdb/#{ferret_service}/edit_versions"

  defp main_page(assigns) do
    ~H"""
    <.page_header
      title={"FerretDB Service: #{@ferret_service.name}"}
      back_button={%{link_type: "live_redirect", to: ~p"/ferretdb"}}
    >
      <:menu>
        <.flex>
          <.data_horizontal_bordered>
            <:item title="Instances"><%= @ferret_service.instances %></:item>
            <:item title="Started">
              <.relative_display time={@ferret_service.inserted_at} />
            </:item>
          </.data_horizontal_bordered>

          <.link navigate={edit_versions_url(@ferret_service)}>
            <.button variant="secondary">
              Edit History
            </.button>
          </.link>

          <.flex gaps="0">
            <.link navigate={edit_url(@ferret_service)}>
              <.button variant="icon" icon={:pencil} />
            </.link>

            <.button variant="icon" icon={:trash} phx-click="delete" data-confirm="Are you sure?" />
          </.flex>
        </.flex>
      </:menu>
    </.page_header>

    <.panel title="Pods">
      <.pods_table pods={@pods} />
    </.panel>
    """
  end

  defp edit_versions_page(assigns) do
    ~H"""
    <.page_header title="Edit History" back_button={%{link_type: "a", to: show_url(@ferret_service)}} />
    <.panel title="Edit History">
      <.edit_versions_table edit_versions={@edit_versions} abbridged />
    </.panel>
    """
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <%= case @live_action do %>
      <% :show -> %>
        <.main_page ferret_service={@ferret_service} pods={@pods} page_title={@page_title} />
      <% :edit_versions -> %>
        <.edit_versions_page ferret_service={@ferret_service} edit_versions={@edit_versions} />
    <% end %>
    """
  end
end
