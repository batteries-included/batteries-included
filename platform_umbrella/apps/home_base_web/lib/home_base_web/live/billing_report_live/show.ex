defmodule HomeBaseWeb.BillingReportLive.Show do
  @moduledoc """
  Show a single billing report and all the data that comes with it.
  """
  use HomeBaseWeb, :live_view

  alias HomeBase.Billing

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:billing_report, Billing.get_billing_report!(id))}
  end

  defp page_title(:show), do: "Show Billing report"
end
