defmodule CommonCore.Postgres.PGCredentialCopy do
  @moduledoc false
  use TypedEctoSchema

  import Ecto.Changeset

  @possible_formats [
    :dsn,
    :user_password,
    :user_password_host
  ]

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :username, :string
    field :namespace, :string
    field :format, Ecto.Enum, values: @possible_formats, default: :user_password_host
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:username, :namespace, :format])
    |> validate_required([:username, :namespace])
  end

  def possible_formats, do: @possible_formats
end
