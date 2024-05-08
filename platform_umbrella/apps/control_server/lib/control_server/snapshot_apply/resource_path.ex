defmodule ControlServer.SnapshotApply.ResourcePath do
  @moduledoc false

  use CommonCore, :schema

  @required_fields [:path, :hash, :type, :name]

  batt_schema "resource_paths" do
    field :path, :string

    field :hash, :string

    field :type, Ecto.Enum, values: CommonCore.ApiVersionKind.all_known()

    field :name, :string
    field :namespace, :string

    field :is_success, :boolean
    field :apply_result, :string

    belongs_to :kube_snapshot, ControlServer.SnapshotApply.KubeSnapshot

    belongs_to :document,
               ControlServer.ContentAddressable.Document

    timestamps()
  end
end
