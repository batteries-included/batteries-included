defmodule HomeBaseWeb.Live.InstallatitonShow do
  @moduledoc false
  use HomeBaseWeb, :live_view

  import HomeBaseWeb.TopMenuLayout

  alias HomeBase.ControlServerClusters

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:installation, ControlServerClusters.get_installation!(id))}
  end

  defp page_title(:show), do: "Show Installation"

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.top_menu_layout page={:installations} title={@page_title}>
      <.data_list>
        <:item title="Slug"><%= @installation.slug %></:item>
      </.data_list>

      <.a navigate={~p"/installations/#{@installation}/show"}>
        <.button>Edit installation</.button>
      </.a>
    </.top_menu_layout>
    """
  end
end
