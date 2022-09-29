defmodule HomeBaseWeb.StripeSubscriptionLiveTest do
  use HomeBaseWeb.ConnCase

  import Phoenix.LiveViewTest
  import HomeBase.LicenseFixtures

  defp create_stripe_subscription(_) do
    stripe_subscription = stripe_subscription_fixture()
    %{stripe_subscription: stripe_subscription}
  end

  describe "Index" do
    setup [:create_stripe_subscription]

    test "lists all stripe_subscriptions", %{conn: conn, stripe_subscription: stripe_subscription} do
      {:ok, _index_live, html} = live(conn, Routes.stripe_subscription_index_path(conn, :index))

      assert html =~ "Listing Stripe subscriptions"
      assert html =~ stripe_subscription.company
    end

    test "deletes stripe_subscription in listing", %{
      conn: conn,
      stripe_subscription: stripe_subscription
    } do
      {:ok, index_live, _html} = live(conn, Routes.stripe_subscription_index_path(conn, :index))

      assert index_live
             |> element("#stripe_subscription-#{stripe_subscription.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#stripe_subscription-#{stripe_subscription.id}")
    end
  end

  describe "Show" do
    setup [:create_stripe_subscription]

    test "displays stripe_subscription", %{conn: conn, stripe_subscription: stripe_subscription} do
      {:ok, _show_live, html} =
        live(conn, Routes.stripe_subscription_show_path(conn, :show, stripe_subscription))

      assert html =~ "Show Stripe subscription"
      assert html =~ stripe_subscription.company
    end
  end
end
