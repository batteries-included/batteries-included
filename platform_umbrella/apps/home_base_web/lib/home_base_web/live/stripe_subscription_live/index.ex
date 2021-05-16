defmodule HomeBaseWeb.StripeSubscriptionLive.Index do
  @moduledoc false
  use HomeBaseWeb, :live_view

  alias HomeBase.License
  alias HomeBase.License.StripeSubscription

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :stripe_subscriptions, list_stripe_subscriptions())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Stripe subscription")
    |> assign(:stripe_subscription, License.get_stripe_subscription!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Stripe subscription")
    |> assign(:stripe_subscription, %StripeSubscription{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Stripe subscriptions")
    |> assign(:stripe_subscription, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    stripe_subscription = License.get_stripe_subscription!(id)
    {:ok, _} = License.delete_stripe_subscription(stripe_subscription)

    {:noreply, assign(socket, :stripe_subscriptions, list_stripe_subscriptions())}
  end

  defp list_stripe_subscriptions do
    License.list_stripe_subscriptions()
  end
end
