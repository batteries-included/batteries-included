defmodule HomeBaseWeb.UsageReportLive.Index do
  @moduledoc """
  List all the latest usage reports. This is a low level ui
  but it can be useful for the demo to show that billing is possible.
  """
  use HomeBaseWeb, :live_view

  alias HomeBase.Usage

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :usage_reports, list_usage_reports())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Usage reports")
    |> assign(:usage_report, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    usage_report = Usage.get_usage_report!(id)
    {:ok, _} = Usage.delete_usage_report(usage_report)

    {:noreply, assign(socket, :usage_reports, list_usage_reports())}
  end

  defp list_usage_reports do
    Usage.list_usage_reports()
  end
end
