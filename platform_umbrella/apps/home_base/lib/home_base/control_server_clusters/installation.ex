defmodule HomeBase.ControlServerClusters.Installation do
  use TypedEctoSchema
  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime_usec]
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "installations" do
    field :slug, :string

    timestamps()
  end

  @doc false
  def changeset(installation, attrs) do
    installation
    |> cast(attrs, [:slug])
    |> validate_required([:slug])
  end
end
