defmodule HomeBase.License do
  @moduledoc """
  The License context.
  """

  import Ecto.Query, warn: false
  alias HomeBase.Repo

  alias HomeBase.License.StripeSubscription

  @doc """
  Returns the list of stripe_subscriptions.

  ## Examples

      iex> list_stripe_subscriptions()
      [%StripeSubscription{}, ...]

  """
  def list_stripe_subscriptions do
    Repo.all(StripeSubscription)
  end

  @doc """
  Gets a single stripe_subscription.

  Raises `Ecto.NoResultsError` if the Stripe subscription does not exist.

  ## Examples

      iex> get_stripe_subscription!(123)
      %StripeSubscription{}

      iex> get_stripe_subscription!(456)
      ** (Ecto.NoResultsError)

  """
  def get_stripe_subscription!(id), do: Repo.get!(StripeSubscription, id)

  @doc """
  Creates a stripe_subscription.

  ## Examples

      iex> create_stripe_subscription(%{field: value})
      {:ok, %StripeSubscription{}}

      iex> create_stripe_subscription(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_stripe_subscription(attrs \\ %{}) do
    %StripeSubscription{}
    |> StripeSubscription.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a stripe_subscription.

  ## Examples

      iex> update_stripe_subscription(stripe_subscription, %{field: new_value})
      {:ok, %StripeSubscription{}}

      iex> update_stripe_subscription(stripe_subscription, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_stripe_subscription(%StripeSubscription{} = stripe_subscription, attrs) do
    stripe_subscription
    |> StripeSubscription.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a stripe_subscription.

  ## Examples

      iex> delete_stripe_subscription(stripe_subscription)
      {:ok, %StripeSubscription{}}

      iex> delete_stripe_subscription(stripe_subscription)
      {:error, %Ecto.Changeset{}}

  """
  def delete_stripe_subscription(%StripeSubscription{} = stripe_subscription) do
    Repo.delete(stripe_subscription)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking stripe_subscription changes.

  ## Examples

      iex> change_stripe_subscription(stripe_subscription)
      %Ecto.Changeset{data: %StripeSubscription{}}

  """
  def change_stripe_subscription(%StripeSubscription{} = stripe_subscription, attrs \\ %{}) do
    StripeSubscription.changeset(stripe_subscription, attrs)
  end
end
