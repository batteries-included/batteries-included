defmodule CommonCore.Knative.Service do
  @moduledoc false

  use CommonCore, {:schema, no_encode: [:project]}

  alias CommonCore.Containers.Container
  alias CommonCore.Projects.Project

  @derive {
    Flop.Schema,
    filterable: [:name], sortable: [:id, :name, :rollout_duration]
  }

  @required_fields ~w(name)a

  batt_schema "knative_services" do
    slug_field :name
    field :rollout_duration, :string, default: "10m"
    field :oauth2_proxy, :boolean, default: false
    field :kube_internal, :boolean, default: false
    field :keycloak_realm, :string

    embeds_many :containers, Container, on_replace: :delete
    embeds_many :init_containers, Container, on_replace: :delete
    embeds_many :env_values, CommonCore.Containers.EnvValue, on_replace: :delete

    belongs_to :project, Project

    timestamps()
  end

  @doc false
  def changeset(struct, attrs, opts \\ []) do
    struct
    |> CommonCore.Ecto.Schema.schema_changeset(attrs, opts)
    |> unique_constraint(:name)
    |> validate_realm()
  end

  def validate(params) do
    changeset =
      %__MODULE__{}
      |> changeset(params)
      |> Map.put(:action, :validate)

    data = Ecto.Changeset.apply_changes(changeset)

    {changeset, data}
  end

  # a keycloak realm is required if oauth2 proxy is enabled
  defp validate_realm(cs), do: validate_realm_for_proxy(get_field(cs, :oauth2_proxy, false), cs)

  defp validate_realm_for_proxy(true, cs), do: validate_required(cs, :keycloak_realm)
  defp validate_realm_for_proxy(_, cs), do: cs

  @doc """
  Function to determine if battery has sso properly configured.
  Useful for e.g. `Enum.filter/2`
  """
  @spec sso_configured_properly?(t()) :: boolean()
  def sso_configured_properly?(service)
  # filter out services that don't have oauth2 proxy enabled
  def sso_configured_properly?(%{oauth2_proxy: false}), do: false
  def sso_configured_properly?(%{oauth2_proxy: nil}), do: false
  # filter out services that don't have a realm
  def sso_configured_properly?(%{keycloak_realm: realm}), do: realm != nil && realm != ""
end
