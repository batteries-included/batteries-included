defmodule Server.Configs.RawConfig do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "raw_configs" do
    field :content, :map, default: %{}, null: false
    field :path, :string
    belongs_to :kube_cluster, Server.Clusters.KubeCluster

    timestamps()
  end

  @doc false
  def changeset(raw_config, attrs) do
    raw_config
    |> cast(attrs, [:path, :content])
    |> validate_required([:path, :content])
  end
end
