defmodule CommonCore.Timeline.Kube do
  @moduledoc false
  use TypedEctoSchema

  import Ecto.Changeset

  @primary_key false
  typed_embedded_schema do
    field :type, Ecto.Enum, values: CommonCore.ApiVersionKind.all_known()
    field :action, Ecto.Enum, values: [:add, :delete, :update]
    field :name, :string
    field :namespace, :string

    field :computed_status, Ecto.Enum,
      values: [
        :ready,
        :containers_ready,
        :initialized,
        :pod_has_network,
        :pod_scheduled,
        :unknown
      ]
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:type, :action, :name, :namespace])
    |> validate_required([:type, :action, :name])
  end
end
