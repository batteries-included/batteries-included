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

  # Maybe Set Virtual Size

  @doc """
  Given a changeset with a `:virtual_size` field, this will apply
  the values from the preset map passed in if the virtual
  size matches the name field of map presets values.
  """
  @spec maybe_set_virtual_size(Ecto.Changeset.t(), list(map())) :: any()
  def maybe_set_virtual_size(changeset, presets) do
    changeset
    |> apply_preset(get_field(changeset, :virtual_size), presets)
    |> maybe_deduce_virtual_size(presets)
  end

  defp maybe_deduce_virtual_size(changeset, presets) do
    # Try and figure out the virtual size from the changeset.
    # If anything doesn't match, then assume custom.
    case get_field(changeset, :virtual_size) do
      nil ->
        matching_preset = find_matching_preset(changeset, presets)

        if matching_preset != nil do
          put_change(changeset, :virtual_size, matching_preset)
        else
          put_change(changeset, :virtual_size, "custom")
        end

      _ ->
        changeset
    end
  end

  defp find_matching_preset(changeset, presets) do
    # Finds the preset that matches the values in the changeset.
    #
    # Returns the `:name` of the matched preset, or `nil` if no match.
    presets
    |> Enum.find(
      %{},
      fn preset ->
        # Check if all keys are either the name which we ignore
        # or they are euqal to the current changeset value.
        Enum.all?(preset, fn {k, v} -> k == :name || get_field(changeset, k) == v end)
      end
    )
    |> Map.get(:name, nil)
  end

  defp apply_preset(changeset, nil, _presets), do: changeset
  defp apply_preset(changeset, "custom" = _preset_name, _presets), do: changeset

  defp apply_preset(changeset, preset_name, presets) do
    preset = Enum.find(presets, &(&1.name == preset_name))

    # Add all preset fields to changeset

    Enum.reduce(preset || %{}, changeset, fn
      {k, _v}, acc when k == :name ->
        acc

      {k, _v}, acc when k == "name" ->
        acc

      {k, v}, acc ->
        put_change(acc, k, v)
    end)
  end
end
