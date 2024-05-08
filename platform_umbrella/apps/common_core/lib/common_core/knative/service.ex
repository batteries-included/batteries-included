defmodule CommonCore.Knative.Service do
  @moduledoc false

  use CommonCore, {:schema, no_encode: [:project]}

  alias CommonCore.Projects.Project

  @required_fields ~w(name)a

  batt_schema "knative_services" do
    slug_field :name
    field :rollout_duration, :string, default: "10m"
    field :oauth2_proxy, :boolean, default: false
    field :kube_internal, :boolean, default: false

    embeds_many :containers, CommonCore.Containers.Container, on_replace: :delete
    embeds_many :init_containers, CommonCore.Containers.Container, on_replace: :delete
    embeds_many :env_values, CommonCore.Containers.EnvValue, on_replace: :delete

    belongs_to :project, Project

    timestamps()
  end

  @doc false
  def changeset(struct, attrs) do
    struct
    |> CommonCore.Ecto.Schema.schema_changeset(attrs)
    |> unique_constraint(:name)
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
