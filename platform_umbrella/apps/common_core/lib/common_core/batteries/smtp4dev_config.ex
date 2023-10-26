defmodule CommonCore.Batteries.Smtp4devConfig do
  @moduledoc false
  use TypedEctoSchema

  import Ecto.Changeset

  alias CommonCore.Defaults
  alias CommonCore.Defaults.RandomKeyChangeset

  @required_fields ~w()a
  @optional_fields ~w(image)a

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :image, :string, default: Defaults.Images.smtp4dev_image()
    field :cookie_secret, :string
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, Enum.concat(@required_fields, @optional_fields))
    |> validate_required(@required_fields)
    |> RandomKeyChangeset.maybe_set_random(:cookie_secret,
      length: 32,
      # NOTE(jdt): we need 32 bytes of key material that are url safely base64 encoded.
      # The default func gives 32 output bytes of traditional base64 encoded material.
      # https://web.archive.org/web/20230504190601/https://oauth2-proxy.github.io/oauth2-proxy/docs/configuration/overview/#generating-a-cookie-secret
      func: fn len ->
        len
        |> :crypto.strong_rand_bytes()
        |> Base.url_encode64()
      end
    )
  end
end
