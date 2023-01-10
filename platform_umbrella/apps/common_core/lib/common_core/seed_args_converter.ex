defmodule CommonCore.SeedArgsConverter do
  alias CommonCore.Batteries.SystemBattery

  @moduledoc """
  This will help convert from Ecto.Schema based structs
  into args that can be used to insert.

  This cleans things that aren't needed after converting
  from structs and takes care of polymorphic embed types

  This is here in CommonCore since any structs that
  have polymorhic types need to specialize here. So
  this seems like the closest place to the owning
  code.
  """

  @bad_keys [:__meta__, :__struct__, :inserted_at, :updated_at]

  def to_fresh_args(%SystemBattery{} = system_battery) do
    system_battery
    |> Map.from_struct()
    |> Map.update(:config, %{}, fn val ->
      # This is a polymorphic type. So we
      # have to add the special field.
      val
      |> to_fresh_args()
      |> Map.put(:__type__, system_battery.type)
    end)
    |> Map.drop(@bad_keys)
    |> Enum.map(fn {key, value} -> {key, to_fresh_args(value)} end)
    |> Map.new()
  end

  def to_fresh_args(s) when is_struct(s) do
    s
    |> Map.from_struct()
    |> Map.drop(@bad_keys)
    |> Enum.map(fn {key, value} -> {key, to_fresh_args(value)} end)
    |> Map.new()
  end

  def to_fresh_args(%{} = m) do
    m
    |> Map.drop(@bad_keys)
    |> Enum.map(fn {key, value} -> {key, to_fresh_args(value)} end)
    |> Map.new()
  end

  def to_fresh_args(l) when is_list(l) do
    Enum.map(l, fn v -> to_fresh_args(v) end)
  end

  def to_fresh_args(v), do: v
end
