defmodule KubeExt.Defaults do
  def random_key_string(length \\ 64) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.encode64(padding: false)
    |> binary_part(0, length)
  end
end
