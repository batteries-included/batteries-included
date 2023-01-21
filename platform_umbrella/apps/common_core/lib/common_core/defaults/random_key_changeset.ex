defmodule CommonCore.Defaults.RandomKeyChangeset do
  import Ecto.Changeset

  @default_length 128

  @doc """
    Adds a random key to the given `field` of the `changeset` if it is `nil`.

    The `opts` keyword list can contain the `:length` option to specify the length of the generated key.
    The default length is `128`.

    ## Examples
    ```elixir
    changeset = Changeset.change(%MyModel{}, %{field: nil})
    CommonCore.Defaults.RandomKeyChangeset.maybe_set_random(changeset, :field, length: 256)

  """
  @spec maybe_set_random(changeset :: Ecto.Changeset.t(), field :: atom, opts :: keyword) ::
          Ecto.Changeset.t()
  def maybe_set_random(changeset, field, opts \\ []) do
    generated_key = get_field(changeset, field)
    new_lenth = Keyword.get(opts, :length, @default_length)

    case generated_key do
      nil ->
        put_change(changeset, field, CommonCore.Defaults.random_key_string(new_lenth))

      _ ->
        changeset
    end
  end
end
