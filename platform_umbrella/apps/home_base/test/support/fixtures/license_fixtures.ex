defmodule HomeBase.LicenseFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HomeBase.License` context.
  """

  @doc """
  Generate a stripe_subscription.
  """
  def stripe_subscription_fixture(attrs \\ %{}) do
    {:ok, stripe_subscription} =
      attrs
      |> Enum.into(%{
        company: "some company",
        stripe_subscription_id: "some stripe_subscription_id"
      })
      |> HomeBase.License.create_stripe_subscription()

    stripe_subscription
  end
end
