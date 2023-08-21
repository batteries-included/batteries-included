defmodule CommonCore.Resources.Secret do
  @moduledoc false
  def encode(map) do
    map
    |> Enum.filter(fn {_key, value} -> value != nil end)
    |> Map.new(fn {key, value} -> {key, Base.encode64(value)} end)
  end

  def decode!(map) do
    Map.new(map, fn {key, value} -> {key, Base.decode64!(value)} end)
  end
end
