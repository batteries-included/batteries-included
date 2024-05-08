defmodule ControlServer.SnapshotApply.UmbrellaSnapshot do
  @moduledoc false

  use CommonCore, :schema

  @derive {
    Flop.Schema,
    filterable: [],
    sortable: [:inserted_at, :id],
    default_limit: 12,
    default_order: %{
      order_by: [:inserted_at, :id],
      order_directions: [:desc, :desc]
    }
  }

  batt_schema "umbrella_snapshots" do
    has_one :kube_snapshot, ControlServer.SnapshotApply.KubeSnapshot
    has_one :keycloak_snapshot, ControlServer.SnapshotApply.KeycloakSnapshot

    timestamps()
  end
end
