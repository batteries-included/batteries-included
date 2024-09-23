defmodule CommonCore.Ecto.Validations do
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

      if down == value do
        change
      else
        put_change(changeset, f, down)
      end
    end)
  end

  @doc """
  Trims whitespace from the values of the given changset fields.

  Returns the updated changeset.
  """
  @spec trim_fields(Ecto.Changeset.t(), list(atom())) :: Ecto.Changeset.t()
  def trim_fields(changeset, fields) do
    Enum.reduce(fields, changeset, fn f, change ->
      value = get_field(change, f)
      trimmed = maybe_trim(value)

      if trimmed == value do
        change
      else
        put_change(changeset, f, trimmed)
      end
    end)
  end

  def validate_read_only(changeset, fields) when is_list(fields) do
    Enum.reduce(fields, changeset, fn f, change ->
      validate_read_only(change, f)
    end)
  end

  @doc """
  Validates that the given field is read-only and cannot be changed.

  This not check on insert, cast, or new actions.
  This also allows a single write from nil to something else.

  Returns the updated changeset.
  """
  def validate_read_only(changeset, field) when is_atom(field) do
    old_value = Map.get(changeset.data, field)
    change_value = get_change(changeset, field)

    cond do
      # Our schema uses changesets to load and create new records
      # So use the action as a method to tell if we are creating a new record
      # or changing an existing one.
      Enum.member?(~w(load new insert cast)a, changeset.action) ->
        changeset

      changeset.data |> Map.get(:__meta__, %{}) |> Map.get(:state, :built) == :built ->
        # Currently Ecto doesn't copy the changeset action on relation changesets
        # So we have a bunch of places that action is nil, but we are actually creating
        # new records. This is a hack to work around that.
        changeset

      old_value == change_value ->
        changeset

      old_value == nil ->
        changeset

      change_value == nil ->
        changeset

      true ->
        add_error(changeset, field, "is read-only and cannot be changed")
    end
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
    CommonCore.Ecto.Validations.maybe_set_random(changeset, :field, length: 256)
    CommonCore.Ecto.Validations.maybe_set_random(changeset, :field, func: fn len ->
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

      "" ->
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

  defp maybe_trim(value) when is_binary(value) do
    String.trim(value)
  end

  defp maybe_trim(value), do: value

  # Maybe Set Virtual Size

  @doc """
  Given a changeset with a `:virtual_size` field, this will apply
  the values from the preset map passed in if the virtual
  size matches the name field of map presets values.
  """
  @spec maybe_set_virtual_size(Ecto.Changeset.t(), list(map())) :: any()
  def maybe_set_virtual_size(changeset, presets) do
    virtual_size = get_field(changeset, :virtual_size)

    changeset
    |> apply_preset(virtual_size, presets)
    |> maybe_deduce_virtual_size(presets)
  end

  defp maybe_deduce_virtual_size(changeset, presets) do
    # Try and figure out the virtual size from the changeset.
    # If anything doesn't match, then assume custom.
    case get_field(changeset, :virtual_size) do
      nil ->
        matching_preset = find_matching_preset(changeset, presets)

        if matching_preset == nil do
          put_change(changeset, :virtual_size, "custom")
        else
          put_change(changeset, :virtual_size, matching_preset)
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

  @spec maybe_fill_in_slug(Ecto.Changeset.t(), atom()) :: Ecto.Changeset.t()
  def maybe_fill_in_slug(changeset, field, opts \\ [length: 3]) do
    generation_enabled = Keyword.get(opts, :autogenerate, true)

    case {generation_enabled, get_field(changeset, field)} do
      {true, nil} ->
        put_change(changeset, field, MnemonicSlugs.generate_slug(Keyword.get(opts, :length, 3)))

      {true, ""} ->
        put_change(changeset, field, MnemonicSlugs.generate_slug(Keyword.get(opts, :length, 3)))

      _ ->
        changeset
    end
  end

  @spec validate_dns_label(Ecto.Changeset.t(), atom()) :: Ecto.Changeset.t()
  def validate_dns_label(changeset, field) do
    changeset
    |> validate_format(field, ~r/^[a-z][a-z0-9-]*$/,
      message: "must start with a letter and only contain alphanumerics and hyphens"
    )
    |> validate_length(field, min: 1, max: 63, message: "must be between 1 and 63 characters")
  end

  @spec validate_email_address(Ecto.Changeset.t(), atom()) :: Ecto.Changeset.t()
  def validate_email_address(changeset, field) do
    changeset
    |> validate_format(field, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(field, max: 160)
  end

  @doc """
  Takes a map of params from subforms and validates them against
  a changeset function defined with the same key. Returns true if
  all the subforms are valid, and false if not.

  ## Example

      params = %{
        "form1" => %{"foo" => "bar"},
        "form2" => %{"baz" => "qux"}
      }

      changesets = %{
        "form1" => &Form1.changeset(%Form1{}, &1),
        "form2" => &Form2.changeset(%Form1{}, &1)
      }

  """
  def subforms_valid?(params, changesets) do
    params
    |> Enum.filter(fn {key, _} -> Map.has_key?(changesets, key) end)
    |> Enum.map(fn {key, values} ->
      {key,
       values
       |> changesets[key].()
       |> apply_action(:insert)}
    end)
    |> Enum.filter(fn {_, {status, _}} -> status != :ok end)
    |> Enum.empty?()
  end

  @doc """
  Adds a new item to an array field in a changeset. If no item
  is specified, an empty string is added. This should be used
  in conjunction with `CommonUI.Components.InputList`.
  """
  def add_item_to_list(changeset, name, item \\ "") do
    items = get_field(changeset, name) || []

    put_change(changeset, name, items ++ [item])
  end

  @doc """
  Removes an item at a specified index from an array field in
  a changeset. This should be used in conjunction with
  `CommonUI.Components.InputList`.
  """
  def remove_item_from_list(changeset, name, index) when is_binary(index) do
    remove_item_from_list(changeset, name, String.to_integer(index))
  end

  def remove_item_from_list(changeset, name, index) do
    items =
      changeset
      |> get_field(name)
      |> List.delete_at(index)

    put_change(changeset, name, items)
  end
end
