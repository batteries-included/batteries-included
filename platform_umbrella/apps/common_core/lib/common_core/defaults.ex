defmodule CommonCore.Defaults do
  @moduledoc false
  def random_key_string(length \\ 64) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.encode32(padding: false)
    |> binary_part(0, length)
  end

  def urlsafe_random_key_string(length \\ 64) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
  end
end
