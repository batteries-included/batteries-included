defmodule Server.Configs.RawConfig do
  @moduledoc """
  The main module for db stored configs.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "raw_configs" do
    field :content, :map, default: %{}, null: false
    field :path, :string, null: false

    timestamps()
  end

  @doc false
  def changeset(raw_config, attrs) do
    raw_config
    |> cast(attrs, [:path, :content])
    |> validate_required([:path, :content])
    |> unique_constraint(:path)
  end
end
