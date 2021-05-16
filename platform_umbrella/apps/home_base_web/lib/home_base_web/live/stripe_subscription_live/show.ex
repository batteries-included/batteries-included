defmodule HomeBaseWeb.StripeSubscriptionLive.Show do
  @moduledoc false
  use HomeBaseWeb, :live_view

  alias HomeBase.License

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:stripe_subscription, License.get_stripe_subscription!(id))}
  end

  defp page_title(:show), do: "Show Stripe subscription"
  defp page_title(:edit), do: "Edit Stripe subscription"
end
