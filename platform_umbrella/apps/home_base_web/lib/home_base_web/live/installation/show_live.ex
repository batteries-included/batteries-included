defmodule HomeBaseWeb.InstallationShowLive do
  @moduledoc false
  use HomeBaseWeb, :live_view

  alias HomeBase.CustomerInstalls

  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page, :installations)
     |> assign(:page_title, "Show Installation")
     |> assign(:installation, CustomerInstalls.get_installation!(id))}
  end

  def render(assigns) do
    ~H"""
    <.data_list>
      <:item title="Slug"><%= @installation.slug %></:item>
    </.data_list>

    <.a navigate={~p"/installations/#{@installation}"}>
      <.button variant="secondary">Edit installation</.button>
    </.a>
    """
  end
end
