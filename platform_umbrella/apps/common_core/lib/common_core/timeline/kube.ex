defmodule CommonCore.Timeline.Kube do
  @moduledoc false

  use CommonCore, :embedded_schema

  batt_polymorphic_schema type: :kube do
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
  end
end
