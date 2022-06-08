defmodule KubeExt.Secret do
  def encode(map) do
    map
    |> Enum.map(fn {key, value} -> {key, Base.encode64(value)} end)
    |> Enum.into(%{})
  end

  def decode!(map) do
    map
    |> Enum.map(fn {key, value} -> {key, Base.decode64!(value)} end)
    |> Enum.into(%{})
  end
end
