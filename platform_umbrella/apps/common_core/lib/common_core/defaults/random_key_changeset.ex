defmodule CommonCore.Defaults.RandomKeyChangeset do
  @moduledoc false
  import Ecto.Changeset

  @default_length 64

  @doc """
    Adds a random key to the given `field` of the `changeset` if it is `nil`.

    The `opts` keyword list can contain:
    - `:length` to specify the length of the generated key. The default length is `64`.
    - `:func` to specify a function to generate the key. The default is `CommonCore.Defaults.random_key_string/1`.

    ## Examples

    ```elixir
    changeset = Changeset.change(%MyModel{}, %{field: nil})
    CommonCore.Defaults.RandomKeyChangeset.maybe_set_random(changeset, :field, length: 256)
    CommonCore.Defaults.RandomKeyChangeset.maybe_set_random(changeset, :field, func: fn len -> 
        String.duplicate("a", len) 
    end)
    ```
  """
  @spec maybe_set_random(changeset :: Ecto.Changeset.t(), field :: atom, opts :: keyword) ::
          Ecto.Changeset.t()
  def maybe_set_random(changeset, field, opts \\ []) do
    generated_key = get_field(changeset, field)
    new_length = Keyword.get(opts, :length, @default_length)
    key_func = Keyword.get(opts, :func, &CommonCore.Defaults.random_key_string/1)

    case generated_key do
      nil ->
        put_change(changeset, field, key_func.(new_length))

      _ ->
        changeset
    end
  end
end
