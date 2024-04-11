defmodule CommonCore.Installation do
  @moduledoc """
  Installation contains the configuration for a single installation of Batteries Included.

  It's all the things needed to bootstrap an installation of Batteries
  Included onto a kubernetes cluster and then bill for it (TODO).
  """
  use TypedEctoSchema

  import Ecto.Changeset

  @required_fields ~w(slug usage kube_provider)a
  @optional_fields ~w(kube_provider_config initial_oauth_email default_size)a

  @timestamps_opts [type: :utc_datetime_usec]
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "installations" do
    field :slug, :string

    # This will be the main switch for specialization
    # of the installation after choosing the where the kubernetes
    # cluster is hosted.
    field :usage, Ecto.Enum,
      values: [:internal_dev, :internal_int_test, :development, :production, :kitchen_sink],
      default: :development

    field :kube_provider, Ecto.Enum, values: [:kind, :aws, :provided]
    field :kube_provider_config, :map, default: %{}

    # Fields for SSO
    field :initial_oauth_email, :string

    # Default size for the installation
    field :default_size, Ecto.Enum,
      values: [:tiny, :small, :medium, :large, :xlarge, :huge],
      default: :medium

    timestamps()
  end

  @doc false
  def changeset(installation, attrs) do
    installation
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    # Slug gets to lowercase
    |> downcase_slug()
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/)
    |> unique_constraint(:slug)
  end

  def downcase_slug(changeset) do
    update_change(changeset, :slug, &String.downcase/1)
  end

  def new(name, opts \\ []) do
    provider_type = Keyword.get(opts, :provider_type, :kind)
    usage = Keyword.get(opts, :usage, :development)
    initial_oauth_email = Keyword.get(opts, :initial_oauth_email, nil)
    default_size = Keyword.get(opts, :default_size, default_size(provider_type, usage))

    %__MODULE__{
      slug: name,
      kube_provider: provider_type,
      kube_provider_config: default_provider_config(provider_type, usage),
      initial_oauth_email: initial_oauth_email,
      default_size: default_size,
      usage: usage
    }
  end

  defp default_size(:kind = _provider_type, _usage), do: :tiny
  defp default_size(:aws = _provider_type, :internal_dev), do: :small
  defp default_size(:aws = _provider_type, _), do: :large
  defp default_size(_, _), do: :medium

  defp default_provider_config(:kind, _usage), do: %{}

  defp default_provider_config(_, _), do: %{}
end
