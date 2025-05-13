defmodule HomeBaseWeb.JwtJSON do
  @moduledoc false

  def show(%{jwt: jwt}) do
    %{jwt: data(jwt)}
  end

  defp data(jwt) do
    # for the keys "payload", "protected", "signature", "ciphertext", "iv", "tag"
    # add them to a map if they exist

    jwt
    |> Map.take(~w[payload protected signature ciphertext iv tag encrypted_key])
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      if value do
        Map.put(acc, key, value)
      else
        acc
      end
    end)
  end
end
