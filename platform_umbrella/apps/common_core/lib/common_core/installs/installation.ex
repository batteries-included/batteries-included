defmodule CommonCore.Installation do
  @moduledoc """
  Installation contains the configuration for a single installation of Batteries Included.

  It's all the things needed to bootstrap an installation of Batteries
  Included onto a kubernetes cluster and then bill for it (TODO).
  """

  use CommonCore, {:schema, no_encode: [:user, :team]}

  import Ecto.SoftDelete.Schema

  alias CommonCore.Accounts.User
  alias CommonCore.Installs.Options
  alias CommonCore.Teams.Team

  @required_fields ~w(usage kube_provider slug)a
  @dialyzer {:nowarn_function, decrypt_message!: 2}

  batt_schema "installations" do
    slug_field :slug

    # This will be the main switch for specialization
    # of the installation after choosing the where the kubernetes
    # cluster is hosted.
    field :usage, Ecto.Enum, values: Keyword.values(Options.usages()), default: :development

    field :kube_provider, Ecto.Enum, values: Keyword.values(Options.providers())
    field :kube_provider_config, :map, default: %{}

    # Default size for the installation
    field :default_size, Ecto.Enum, values: Options.sizes(), default: :medium

    field :control_jwk, :map, redact: true

    belongs_to :user, User
    belongs_to :team, Team

    timestamps()
    soft_delete_schema()
  end

  @doc false
  def changeset(installation, attrs \\ %{}, opts \\ []) do
    installation
    |> CommonCore.Ecto.Schema.schema_changeset(attrs, opts)
    |> maybe_add_control_jwk()
    |> foreign_key_constraint(:slug)
  end

  @default_provider_type :kind
  @default_usage :development

  def new!(name, opts \\ [])

  def new!(name, opts) when is_binary(name) do
    provider_type = Keyword.get(opts, :kube_provider, @default_provider_type)
    usage = Keyword.get(opts, :usage, @default_usage)

    opts =
      opts
      |> Keyword.put_new_lazy(:slug, fn -> normalize_slug(name) end)
      |> Keyword.put_new(:kube_provider, provider_type)
      |> Keyword.put_new(:kube_provider_config, default_provider_config(provider_type, usage))
      |> Keyword.put_new(:usage, @default_usage)
      |> Keyword.put_new(:default_size, default_size(provider_type, usage))

    with {:ok, installation} <- new(opts) do
      installation
    end
  end

  def new!(passed_opts, opts) do
    opts = Keyword.merge(opts || [], passed_opts)
    name = Keyword.fetch!(opts, :name)

    new!(name, opts)
  end

  @spec default_size(atom(), atom()) :: :large | :medium | :small | :tiny
  @doc """
  Returns the default size for a given provider and usage.

  ## Params

    * `provider_type` - The type of provider to use.
    * `usage` - The usage of the installation.


  ## Examples

      iex> default_size(:kind, :development)
      :tiny

      iex> default_size(:aws, :development)
      :small

      iex> default_size(:aws, :production)
      :large
  """
  def default_size(:kind = _provider_type, _usage), do: :tiny
  def default_size(:aws = _provider_type, :internal_dev), do: :small
  def default_size(:aws = _provider_type, :development), do: :small
  def default_size(:aws = _provider_type, _), do: :large
  def default_size(_, _), do: :medium

  defp default_provider_config(_, _), do: %{}

  defp maybe_add_control_jwk(changeset) do
    case get_field(changeset, :control_jwk) do
      nil ->
        put_change(changeset, :control_jwk, CommonCore.JWK.generate_key())

      _ ->
        changeset
    end
  end

  def verify_message!(%__MODULE__{control_jwk: control_jwk}, message) do
    case JOSE.JWT.verify(control_jwk, message) do
      {true, jwt, _} ->
        {_, map} = JOSE.JWT.to_map(jwt)
        map

      {false, _, _} ->
        raise CommonCore.JWK.BadKeyError.exception()
    end
  end

  def decrypt_message!(%__MODULE__{control_jwk: control_jwk}, message) do
    CommonCore.JWK.decrypt_from_control_server!(control_jwk, message)
  end

  def normalize_slug(name) do
    name
    # We don't want no stinking caps lock
    |> String.downcase()
    # Everything else is a dash
    |> String.replace(~r/[^a-z0-9]/, "-")
    # Remove duplicate dashes
    |> String.replace(~r/-+/, "-")
    # Trim them from the ends
    |> String.trim("-")
  end
end
