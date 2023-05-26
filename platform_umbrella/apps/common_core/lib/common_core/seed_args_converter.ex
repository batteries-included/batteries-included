defmodule CommonCore.SeedArgsConverter do
  @moduledoc """
  This will help convert from json
  into args that can be used to insert.

  This is here in CommonCore since any structs that
  have polymorhic types need to specialize here. So
  this seems like the closest place to the owning
  code.
  """

  @bad_keys [:__meta__, :__struct__, :inserted_at, :updated_at, "inserted_at", "updated_at", "id"]

  def to_fresh_battery_args(%{} = system_battery) do
    raw_battery =
      system_battery
      |> to_fresh_args()
      |> Map.update!(:type, fn val -> String.to_atom(val) end)

    Map.update(raw_battery, :config, %{}, fn val ->
      # This is a polymorphic type. So we
      # have to add the special field.

      Map.put_new(val, "__type__", raw_battery.type)
    end)
  end

  def to_fresh_args(%{} = m) do
    m
    |> Enum.map(fn {key, value} -> {to_key(key), value} end)
    |> Map.new()
    |> Map.drop(@bad_keys)
  end

  def to_key(key) when is_binary(key), do: String.to_atom(key)
  def to_key(key) when is_atom(key), do: key
end
