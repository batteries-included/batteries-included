defmodule HomeBaseWeb.LiveHelpers do
  @moduledoc false
  import Phoenix.LiveView.Helpers

  @doc """
  Renders a component inside the `HomeBaseWeb.ModalComponent` component.

  The rendered modal receives a `:return_to` option to properly update
  the URL when the modal is closed.

  ## Examples

      <%= live_modal HomeBaseWeb.StripeSubscriptionLive.FormComponent,
        id: @stripe_subscription.id || :new,
        action: @live_action,
        stripe_subscription: @stripe_subscription,
        return_to: Routes.stripe_subscription_index_path(@socket, :index) %>
  """
  def live_modal(component, opts) do
    path = Keyword.fetch!(opts, :return_to)
    modal_opts = [id: :modal, return_to: path, component: component, opts: opts]
    live_component(HomeBaseWeb.ModalComponent, modal_opts)
  end
end
