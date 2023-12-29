defmodule CommonCore.Timeline.Kube do
  @moduledoc false
  use CommonCore.Util.PolymorphicType, type: :kube
  use TypedEctoSchema

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :resource_type, Ecto.Enum, values: CommonCore.ApiVersionKind.all_known()
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

    type_field()
  end
end
