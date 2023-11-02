defmodule CommonCore.Batteries.NotebooksConfig do
  @moduledoc false
  use TypedEctoSchema

  import Ecto.Changeset

  alias CommonCore.Defaults
  alias CommonCore.Defaults.RandomKeyChangeset

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :cookie_secret, :string
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [])
    |> RandomKeyChangeset.maybe_set_random(:cookie_secret, length: 32, func: &Defaults.urlsafe_random_key_string/1)
  end
end
