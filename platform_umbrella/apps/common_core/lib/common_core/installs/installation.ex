defmodule CommonCore.Installation do
  @moduledoc """
  Installation contains the configuration for a single installation of Batteries Included.

  It's all the things needed to bootstrap an installation of Batteries
  Included onto a kubernetes cluster and then bill for it (TODO).
  """

  use CommonCore, :schema

  @required_fields ~w(usage kube_provider slug)a

  @sizes [:tiny, :small, :medium, :large, :xlarge, :huge]
  @providers [Kind: :kind, AWS: :aws, Provided: :provided]
  @usages [
    "Kitchen Sink": :kitchen_sink,
    "Internal Dev": :internal_dev,
    "Internal Test": :internal_int_test,
    Development: :development,
    Production: :production
  ]

  batt_schema "installations" do
    slug_field :slug

    # This will be the main switch for specialization
    # of the installation after choosing the where the kubernetes
    # cluster is hosted.
    field :usage, Ecto.Enum, values: Keyword.values(@usages), default: :development

    field :kube_provider, Ecto.Enum, values: Keyword.values(@providers)
    field :kube_provider_config, :map, default: %{}

    # Fields for SSO
    field :sso_enabled, :boolean, default: false
    field :initial_oauth_email, :string

    # Default size for the installation
    field :default_size, Ecto.Enum, values: @sizes, default: :medium

    # Use `field` rather than `belongs_to` to prevent a circular dependency with HomeBase
    field :user_id, CommonCore.Ecto.BatteryUUID
    field :team_id, CommonCore.Ecto.BatteryUUID

    timestamps()
  end

  @doc false
  def changeset(installation, attrs \\ %{}) do
    installation
    |> CommonCore.Ecto.Schema.schema_changeset(attrs)
    |> maybe_require_oauth_email(attrs)
    |> downcase_slug()
    |> validate_email_address(:initial_oauth_email)
    |> unique_constraint(:slug)
  end

  def maybe_require_oauth_email(changeset, %{"sso_enabled" => true}) do
    validate_required(changeset, [:initial_oauth_email])
  end

  def maybe_require_oauth_email(changeset, _attrs), do: changeset

  def downcase_slug(changeset) do
    update_change(changeset, :slug, &String.downcase/1)
  end

  def new!(name, opts \\ []) do
    provider_type = Keyword.get(opts, :provider_type, :kind)
    usage = Keyword.get(opts, :usage, :development)
    initial_oauth_email = Keyword.get(opts, :initial_oauth_email, nil)
    default_size = Keyword.get(opts, :default_size, default_size(provider_type, usage))

    with {:ok, install} <-
           new(
             slug: name,
             kube_provider: provider_type,
             kube_provider_config: default_provider_config(provider_type, usage),
             initial_oauth_email: initial_oauth_email,
             default_size: default_size,
             usage: usage
           ) do
      install
    end
  end

  def size_options, do: Enum.map(@sizes, &{&1 |> Atom.to_string() |> String.capitalize(), &1})
  def provider_options, do: @providers
  def usage_options, do: @usages

  defp default_size(:kind = _provider_type, _usage), do: :tiny
  defp default_size(:aws = _provider_type, :internal_dev), do: :small
  defp default_size(:aws = _provider_type, :development), do: :small
  defp default_size(:aws = _provider_type, _), do: :large
  defp default_size(_, _), do: :medium

  defp default_provider_config(:kind, _usage), do: %{}

  defp default_provider_config(_, _), do: %{}
end
