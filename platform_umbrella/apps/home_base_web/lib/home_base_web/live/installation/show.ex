defmodule HomeBaseWeb.Live.InstallatitonShow do
  use HomeBaseWeb, :live_view

  import HomeBaseWeb.TopMenuLayout

  alias HomeBase.ControlServerClusters

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:installation, ControlServerClusters.get_installation!(id))}
  end

  defp page_title(:show), do: "Show Installation"

  @impl true
  def render(assigns) do
    ~H"""
    <.top_menu_layout page={:installations} title={@page_title}>
      <.data_list>
        <:item title="Slug"><%= @installation.slug %></:item>
      </.data_list>

      <.link navigate={~p"/installations/#{@installation}/show"}>
        <.button>Edit installation</.button>
      </.link>
    </.top_menu_layout>
    """
  end
end
