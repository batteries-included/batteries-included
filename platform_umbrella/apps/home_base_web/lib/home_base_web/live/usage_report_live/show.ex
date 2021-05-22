defmodule HomeBaseWeb.UsageReportLive.Show do
  @moduledoc false
  use HomeBaseWeb, :live_view

  alias HomeBase.Usage

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:usage_report, Usage.get_usage_report!(id))}
  end

  defp page_title(:show), do: "Show Usage report"
end
