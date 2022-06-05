defmodule ControlServer.Knative.Service do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "services" do
    field :name, :string
    field :image, :string

    timestamps()
  end

  @doc false
  def changeset(service, attrs) do
    service
    |> cast(attrs, [:name, :image])
    |> validate_required([:name, :image])
  end

  def validate(params) do
    changeset =
      %__MODULE__{}
      |> changeset(params)
      |> Map.put(:action, :validate)

    data = Ecto.Changeset.apply_changes(changeset)

    {changeset, data}
  end

  # TODO: validate that we can reach whatever registry/image/version is set
  #       in :image; at least warn if we can't
end
