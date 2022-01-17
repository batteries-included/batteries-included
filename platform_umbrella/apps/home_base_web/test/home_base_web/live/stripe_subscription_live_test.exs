defmodule HomeBaseWeb.StripeSubscriptionLiveTest do
  use HomeBaseWeb.ConnCase

  import Phoenix.LiveViewTest
  import HomeBase.LicenseFixtures

  @create_attrs %{company: "some company", stripe_subscription_id: "some stripe_subscription_id"}
  @update_attrs %{
    company: "some updated company",
    stripe_subscription_id: "some updated stripe_subscription_id"
  }
  @invalid_attrs %{company: nil, stripe_subscription_id: nil}

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

    test "saves new stripe_subscription", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.stripe_subscription_index_path(conn, :index))

      assert index_live |> element("a", "New Stripe subscription") |> render_click() =~
               "New Stripe subscription"

      assert_patch(index_live, Routes.stripe_subscription_index_path(conn, :new))

      assert index_live
             |> form("#stripe_subscription-form", stripe_subscription: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#stripe_subscription-form", stripe_subscription: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.stripe_subscription_index_path(conn, :index))

      assert html =~ "Stripe subscription created successfully"
      assert html =~ "some company"
    end

    test "updates stripe_subscription in listing", %{
      conn: conn,
      stripe_subscription: stripe_subscription
    } do
      {:ok, index_live, _html} = live(conn, Routes.stripe_subscription_index_path(conn, :index))

      assert index_live
             |> element("#stripe_subscription-#{stripe_subscription.id} a", "Edit")
             |> render_click() =~
               "Edit Stripe subscription"

      assert_patch(
        index_live,
        Routes.stripe_subscription_index_path(conn, :edit, stripe_subscription)
      )

      assert index_live
             |> form("#stripe_subscription-form", stripe_subscription: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#stripe_subscription-form", stripe_subscription: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.stripe_subscription_index_path(conn, :index))

      assert html =~ "Stripe subscription updated successfully"
      assert html =~ "some updated company"
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

    test "updates stripe_subscription within modal", %{
      conn: conn,
      stripe_subscription: stripe_subscription
    } do
      {:ok, show_live, _html} =
        live(conn, Routes.stripe_subscription_show_path(conn, :show, stripe_subscription))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Stripe subscription"

      assert_patch(
        show_live,
        Routes.stripe_subscription_show_path(conn, :edit, stripe_subscription)
      )

      assert show_live
             |> form("#stripe_subscription-form", stripe_subscription: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#stripe_subscription-form", stripe_subscription: @update_attrs)
        |> render_submit()
        |> follow_redirect(
          conn,
          Routes.stripe_subscription_show_path(conn, :show, stripe_subscription)
        )

      assert html =~ "Stripe subscription updated successfully"
      assert html =~ "some updated company"
    end
  end
end
