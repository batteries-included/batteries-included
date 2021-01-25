defmodule ServerWeb.RawConfigLive.Show do
  use ServerWeb, :live_view

  alias Server.Configs

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:raw_config, Configs.get_raw_config!(id))}
  end

  defp page_title(:show), do: "Show Raw config"
  defp page_title(:edit), do: "Edit Raw config"
end
