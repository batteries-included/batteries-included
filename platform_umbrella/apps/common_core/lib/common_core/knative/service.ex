defmodule CommonCore.Knative.Service do
  @moduledoc false
  use TypedEctoSchema

  import CommonCore.Util.EctoValidations
  import Ecto.Changeset

  @required_fields ~w(name)a
  @optional_fields ~w(rollout_duration oauth2_proxy)a

  @timestamps_opts [type: :utc_datetime_usec]
  @derive {Jason.Encoder, except: [:__meta__]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "knative_services" do
    field :name, :string, null: false
    field :rollout_duration, :string, default: "10m"
    field :oauth2_proxy, :boolean, default: false
    field :kube_internal, :boolean, default: false

    embeds_many(:containers, CommonCore.Services.Container, on_replace: :delete)
    embeds_many(:init_containers, CommonCore.Services.Container, on_replace: :delete)
    embeds_many(:env_values, CommonCore.Services.EnvValue, on_replace: :delete)
    timestamps()
  end

  @doc false
  def changeset(struct, attrs) do
    struct
    |> cast(attrs, Enum.concat(@required_fields, @optional_fields))
    |> validate_required(@required_fields)
    |> downcase_fields([:name])
    |> unique_constraint(:name)
    |> cast_embed(:containers)
    |> cast_embed(:init_containers)
    |> cast_embed(:env_values)
  end

  def validate(params) do
    changeset =
      %__MODULE__{}
      |> changeset(params)
      |> Map.put(:action, :validate)

    data = Ecto.Changeset.apply_changes(changeset)

    {changeset, data}
  end
end
