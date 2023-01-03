defmodule CommonCore.Timeline.Kube do
  use TypedEctoSchema
  import Ecto.Changeset

  @primary_key false
  typed_embedded_schema do
    field :type, Ecto.Enum, values: CommonCore.ApiVersionKind.all_known()
    field :action, Ecto.Enum, values: [:add, :delete, :update]
    field :name, :string
    field :namespace, :string
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:type, :action, :name, :namespace])
    |> validate_required([:type, :action, :name])
  end
end
