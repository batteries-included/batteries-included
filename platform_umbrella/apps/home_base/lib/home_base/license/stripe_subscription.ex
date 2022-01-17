defmodule HomeBase.License.StripeSubscription do
  use Ecto.Schema
  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime_usec]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "stripe_subscriptions" do
    field :company, :string
    field :stripe_subscription_id, :string

    timestamps()
  end

  @doc false
  def changeset(stripe_subscription, attrs) do
    stripe_subscription
    |> cast(attrs, [:company, :stripe_subscription_id])
    |> validate_required([:company, :stripe_subscription_id])
  end
end
