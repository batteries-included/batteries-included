defmodule ControlServer.Timeline.NamedDatabase do
  use TypedEctoSchema
  import Ecto.Changeset

  @primary_key false
  typed_embedded_schema do
    field :action, Ecto.Enum, values: EventCenter.Database.allowed_actions()
    field :type, Ecto.Enum, values: EventCenter.Database.allowed_sources()
    field :name, :string
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:action, :type, :name])
    |> validate_required([:action, :type])
  end
end
