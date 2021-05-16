defmodule HomeBaseWeb.StripeSubscriptionLive.FormComponent do
  @moduledoc false
  use HomeBaseWeb, :live_component

  alias HomeBase.License

  @impl true
  def update(%{stripe_subscription: stripe_subscription} = assigns, socket) do
    changeset = License.change_stripe_subscription(stripe_subscription)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"stripe_subscription" => stripe_subscription_params}, socket) do
    changeset =
      socket.assigns.stripe_subscription
      |> License.change_stripe_subscription(stripe_subscription_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"stripe_subscription" => stripe_subscription_params}, socket) do
    save_stripe_subscription(socket, socket.assigns.action, stripe_subscription_params)
  end

  defp save_stripe_subscription(socket, :edit, stripe_subscription_params) do
    case License.update_stripe_subscription(
           socket.assigns.stripe_subscription,
           stripe_subscription_params
         ) do
      {:ok, _stripe_subscription} ->
        {:noreply,
         socket
         |> put_flash(:info, "Stripe subscription updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_stripe_subscription(socket, :new, stripe_subscription_params) do
    case License.create_stripe_subscription(stripe_subscription_params) do
      {:ok, _stripe_subscription} ->
        {:noreply,
         socket
         |> put_flash(:info, "Stripe subscription created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
