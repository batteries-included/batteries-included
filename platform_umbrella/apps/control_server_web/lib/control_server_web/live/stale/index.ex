defmodule ControlServerWeb.Live.StaleIndex do
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout
  import K8s.Resource.FieldAccessors

  alias KubeServices.Stale
  alias CommonCore.ApiVersionKind
  alias Phoenix.Naming

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.layout group={:magic} active={:stale}>
      <:title>
        <.title><%= @page_title %></.title>
      </:title>
      <.table id="stale-table" rows={@stale}>
        <:col :let={resource} label="Kind">
          <%= Naming.humanize(ApiVersionKind.resource_type!(resource)) %>
        </:col>
        <:col :let={resource} label="Name">
          <%= name(resource) %>
        </:col>
        <:col :let={resource} label="Namespace">
          <%= namespace(resource) %>
        </:col>
      </.table>
    </.layout>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _uri, socket) do
    {:noreply,
     socket
     |> assign_stale(fetch_stale())
     |> assign_page_title("Stale Deleter Queue")}
  end

  def assign_stale(socket, stale) do
    assign(socket, stale: stale)
  end

  def assign_page_title(socket, page_title) do
    assign(socket, page_title: page_title)
  end

  defp fetch_stale, do: Stale.find_potential_stale()
end
