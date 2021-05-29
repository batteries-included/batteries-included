defmodule HomeBaseWeb.BillingReportLive.Index do
  @moduledoc """
  List all the billing reports
  """
  use HomeBaseWeb, :live_view

  alias HomeBase.Billing

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :billing_reports, list_billing_reports())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Billing reports")
    |> assign(:billing_report, nil)
  end

  defp list_billing_reports do
    Billing.list_billing_reports()
  end

  @impl true
  def handle_event("start_billing", _value, socket) do
    with {:ok, _report} <- HomeBase.Billing.generate_billing_report(DateTime.utc_now()) do
      {:noreply, assign(socket, :billing_reports, list_billing_reports())}
    end
  end
end
