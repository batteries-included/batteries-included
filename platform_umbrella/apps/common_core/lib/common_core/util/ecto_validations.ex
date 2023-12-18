defmodule CommonCore.Util.EctoValidations do
  @moduledoc false

  import Ecto.Changeset

  alias CommonCore.Defaults

  @doc """
  Downcases the values of the given fields in the changeset.

  Takes a changeset and a list of field names. Finds the current
  value of each field, downcases it if it is a binary, and puts it
  back in the changeset with put_change/3 if the value changed.

  Returns the updated changeset.
  """
  @spec downcase_fields(Ecto.Changeset.t(), list(atom())) :: Ecto.Changeset.t()
  def downcase_fields(changeset, fields) do
    Enum.reduce(fields, changeset, fn f, change ->
      value = get_field(change, f)
      down = maybe_downcase(value)

      if down != value do
        put_change(changeset, f, down)
      else
        change
      end
    end)
  end

  @default_length 64

  @doc """
    Adds a random key to the given `field` of the `changeset` if it is `nil`.

    The `opts` keyword list can contain:
    - `:length` to specify the length of the generated key. The default length is `64`.
    - `:func` to specify a function to generate the key. The default is `CommonCore.Defaults.random_key_string/1`.

    ## Examples

    ```elixir
    changeset = Changeset.change(%MyModel{}, %{field: nil})
    CommonCore.Util.EctoValidations.maybe_set_random(changeset, :field, length: 256)
    CommonCore.Util.EctoValidations.maybe_set_random(changeset, :field, func: fn len ->
        String.duplicate("a", len)
    end)
    ```
  """
  @spec maybe_set_random(changeset :: Ecto.Changeset.t(), field :: atom, opts :: keyword) ::
          Ecto.Changeset.t()
  def maybe_set_random(changeset, field, opts \\ []) do
    new_length = Keyword.get(opts, :length, @default_length)

    key_func = Keyword.get(opts, :func, &CommonCore.Defaults.random_key_string/1)

    case get_field(changeset, field) do
      nil ->
        put_change(changeset, field, key_func.(new_length))

      _ ->
        changeset
    end
  end

  @doc """
  Add a random string to the `:cookie_secret` field in with the preconfigured for Oauth2's
  cookie.
  """
  @spec validate_cookie_secret(changeset :: Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def validate_cookie_secret(changeset, field \\ :cookie_secret) do
    maybe_set_random(changeset, field, length: 32, func: &Defaults.urlsafe_random_key_string/1)
  end

  defp maybe_downcase(value) when is_binary(value) do
    String.downcase(value)
  end

  defp maybe_downcase(value), do: value
end
