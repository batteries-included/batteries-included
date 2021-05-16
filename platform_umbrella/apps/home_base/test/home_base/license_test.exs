defmodule HomeBase.LicenseTest do
  use HomeBase.DataCase

  alias HomeBase.License

  describe "stripe_subscriptions" do
    alias HomeBase.License.StripeSubscription

    @valid_attrs %{company: "some company", stripe_subscription_id: "some stripe_subscription_id"}
    @update_attrs %{
      company: "some updated company",
      stripe_subscription_id: "some updated stripe_subscription_id"
    }
    @invalid_attrs %{company: nil, stripe_subscription_id: nil}

    def stripe_subscription_fixture(attrs \\ %{}) do
      {:ok, stripe_subscription} =
        attrs
        |> Enum.into(@valid_attrs)
        |> License.create_stripe_subscription()

      stripe_subscription
    end

    test "list_stripe_subscriptions/0 returns all stripe_subscriptions" do
      stripe_subscription = stripe_subscription_fixture()
      assert License.list_stripe_subscriptions() == [stripe_subscription]
    end

    test "get_stripe_subscription!/1 returns the stripe_subscription with given id" do
      stripe_subscription = stripe_subscription_fixture()
      assert License.get_stripe_subscription!(stripe_subscription.id) == stripe_subscription
    end

    test "create_stripe_subscription/1 with valid data creates a stripe_subscription" do
      assert {:ok, %StripeSubscription{} = stripe_subscription} =
               License.create_stripe_subscription(@valid_attrs)

      assert stripe_subscription.company == "some company"
      assert stripe_subscription.stripe_subscription_id == "some stripe_subscription_id"
    end

    test "create_stripe_subscription/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = License.create_stripe_subscription(@invalid_attrs)
    end

    test "update_stripe_subscription/2 with valid data updates the stripe_subscription" do
      stripe_subscription = stripe_subscription_fixture()

      assert {:ok, %StripeSubscription{} = stripe_subscription} =
               License.update_stripe_subscription(stripe_subscription, @update_attrs)

      assert stripe_subscription.company == "some updated company"
      assert stripe_subscription.stripe_subscription_id == "some updated stripe_subscription_id"
    end

    test "update_stripe_subscription/2 with invalid data returns error changeset" do
      stripe_subscription = stripe_subscription_fixture()

      assert {:error, %Ecto.Changeset{}} =
               License.update_stripe_subscription(stripe_subscription, @invalid_attrs)

      assert stripe_subscription == License.get_stripe_subscription!(stripe_subscription.id)
    end

    test "delete_stripe_subscription/1 deletes the stripe_subscription" do
      stripe_subscription = stripe_subscription_fixture()

      assert {:ok, %StripeSubscription{}} =
               License.delete_stripe_subscription(stripe_subscription)

      assert_raise Ecto.NoResultsError, fn ->
        License.get_stripe_subscription!(stripe_subscription.id)
      end
    end

    test "change_stripe_subscription/1 returns a stripe_subscription changeset" do
      stripe_subscription = stripe_subscription_fixture()
      assert %Ecto.Changeset{} = License.change_stripe_subscription(stripe_subscription)
    end
  end
end
