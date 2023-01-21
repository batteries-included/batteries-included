defmodule CommonCore.Defaults.RandomKeyChangeset do
  import Ecto.Changeset

  @default_length 128

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
