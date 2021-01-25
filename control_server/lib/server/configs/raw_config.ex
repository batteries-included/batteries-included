defmodule Server.Configs.RawConfig do
  use Ecto.Schema
  import Ecto.Changeset

  schema "raw_configs" do
    field :content, :map, default: %{}, null: false
    field :path, :string
    belongs_to :kube_cluster, KubeCluster

    timestamps()
  end

  @doc false
  def changeset(raw_config, attrs) do
    raw_config
    |> cast(attrs, [:path, :content])
    |> validate_required([:path, :content])
  end
end
